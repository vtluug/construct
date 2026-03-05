{
  lib,
  lan_iface,
  lan,
  ...
}:
let
  hosts = import ./static-hosts.nix;
  dnsmasq-hosts = builtins.map (host: "${host.mac},${host.ipv4},${host.name}") hosts;

  tagged_vlans = (
    builtins.filter (e: !builtins.hasAttr "untagged" e.snd) (
      lib.lists.zipLists (builtins.attrNames lan) (builtins.attrValues lan)
    )
  );
  untagged_vlan = lib.lists.findFirst (
    e: builtins.hasAttr "untagged" e
  ) (throw "Must have untagged VLAN") (builtins.attrValues lan);
in
{
  services.dnsmasq = {
    enable = true;
    settings = {
      interface = [
        lan_iface
      ]
      ++ builtins.map (e: "vlan${e.fst}") tagged_vlans;
      dhcp-range =
        (lib.lists.optional (builtins.hasAttr "dhcpv4" untagged_vlan) "interface:${lan_iface},${untagged_vlan.dhcpv4}")
        ++ (lib.lists.optional (builtins.hasAttr "dhcpv6" untagged_vlan) "interface:${lan_iface},::,constructor:${lan_iface},${untagged_vlan.dhcpv6}")
        ++ (builtins.map (e: "interface:vlan${e.fst},${e.snd.dhcpv4}") (
          builtins.filter (e: builtins.hasAttr "dhcpv4" e.snd) tagged_vlans
        ))
        ++ (builtins.map (e: "interface:vlan${e.fst},::,constructor:vlan${e.fst},${e.snd.dhcpv6}") (
          builtins.filter (e: builtins.hasAttr "dhcpv6" e.snd) tagged_vlans
        ));
      dhcp-host = dnsmasq-hosts;
    };
  };
}
