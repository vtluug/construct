{
  lib,
  lanIface,
  lan,
  ...
}:
let
  hosts = import ./static-hosts.nix;
  dnsmasqHosts = builtins.map (host: "${host.mac},${host.ipv4},${host.name}") hosts;
  globalDomain = "mcb.vtluug.org";

  taggedVlans = (
    builtins.filter (e: !builtins.hasAttr "untagged" e.snd) (
      lib.lists.zipLists (builtins.attrNames lan) (builtins.attrValues lan)
    )
  );
  untaggedVlan = lib.lists.findFirst (
    e: builtins.hasAttr "untagged" e
  ) (throw "Must have untagged VLAN") (builtins.attrValues lan);

  interfaces = builtins.map (e: "vlan${e.fst}") (
    builtins.filter (
      e: (builtins.hasAttr "dhcpv4" e.snd) || (builtins.hasAttr "dhcpv6" e.snd)
    ) taggedVlans
  );
in
{
  networking.nameservers = [
    "::"
    "127.0.0.1"
  ];

  # DNS, DHCPv4, DHCPv6
  networking.firewall.allowedUDPPorts = [
    53
    67
    547
  ];

  services.dnsmasq = {
    enable = true;
    settings = {
      domain =
        (lib.lists.optional (builtins.hasAttr "domain" untaggedVlan) "${untaggedVlan.domain}.${globalDomain},${untaggedVlan.ipv4.address}/${toString untaggedVlan.ipv4.cidr}")
        ++ (builtins.map (
          e: "${e.snd.domain}.${globalDomain},${e.snd.ipv4.address}/${toString e.snd.ipv4.cidr}"
        ) (builtins.filter (e: builtins.hasAttr "domain" e.snd) taggedVlans));
      server = [
          "9.9.9.9"
          "2620:fe::fe"
          "1.1.1.1"
          "2606:4700:4700::1111"
          "/whit.vtluug.org/10.98.3.2"
          "/bastille.vtluug.org/10.98.3.2"
      ];
      interface =
        (lib.lists.optional (
          (builtins.hasAttr "dhcpv4" untaggedVlan) || (builtins.hasAttr "dhcpv6" untaggedVlan)
        ) lanIface)
        ++ interfaces;
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
