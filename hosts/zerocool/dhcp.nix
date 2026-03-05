{
  lib,
  lanIface,
  lan,
  ...
}:
let
  hosts = import ./static-hosts.nix;
  dnsmasqHosts = builtins.map (host: "${host.mac},${host.ipv4},${host.name}") hosts;

  taggedVlans = (
    builtins.filter (e: !builtins.hasAttr "untagged" e.snd) (
      lib.lists.zipLists (builtins.attrNames lan) (builtins.attrValues lan)
    )
  );
  untaggedVlan = lib.lists.findFirst (
    e: builtins.hasAttr "untagged" e
  ) (throw "Must have untagged VLAN") (builtins.attrValues lan);
in
{
  services.dnsmasq = {
    enable = true;
    settings = {
      interface = [
        lanIface
      ]
      ++ builtins.map (e: "vlan${e.fst}") taggedVlans;
      dhcp-range =
        (lib.lists.optional (builtins.hasAttr "dhcpv4" untaggedVlan) "interface:${lanIface},${untaggedVlan.dhcpv4}")
        ++ (lib.lists.optional (builtins.hasAttr "dhcpv6" untaggedVlan) "interface:${lanIface},::,constructor:${lanIface},${untaggedVlan.dhcpv6}")
        ++ (builtins.map (e: "interface:vlan${e.fst},${e.snd.dhcpv4}") (
          builtins.filter (e: builtins.hasAttr "dhcpv4" e.snd) taggedVlans
        ))
        ++ (builtins.map (e: "interface:vlan${e.fst},::,constructor:vlan${e.fst},${e.snd.dhcpv6}") (
          builtins.filter (e: builtins.hasAttr "dhcpv6" e.snd) taggedVlans
        ));
      dhcp-host = dnsmasqHosts;
    };
  };
}
