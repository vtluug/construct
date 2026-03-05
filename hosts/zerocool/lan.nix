{
  lib,
  lan_iface,
  lan,
  ...
}:
let
  # First element in LAN is always the untagged VLAN
  untagged_lan_attrs = lib.lists.findFirst (
    e: builtins.hasAttr "untagged" e
  ) (throw "Must have untagged VLAN") (builtins.attrValues lan);
in
{
  networking.vlans = builtins.listToAttrs (
    builtins.map
      (e: {
        name = "vlan${e.fst}";
        value = {
          id = builtins.fromJSON e.fst;
          interface = lan_iface;
        };
      })
      (
        builtins.filter (e: !builtins.hasAttr "untagged" e.snd) (
          lib.lists.zipLists (builtins.attrNames lan) (builtins.attrValues lan)
        )
      )
  );

  networking.interfaces = builtins.listToAttrs (
    # Tagged VLANs
    (builtins.map
      (e: {
        name = "vlan${e.fst}";
        value = {
          useDHCP = false;
          ipv4.addresses = [
            {
              address = e.snd.ipv4.address;
              prefixLength = e.snd.ipv4.cidr;
            }
          ];
          ipv6.addresses = [
            {
              address = e.snd.ipv6.address;
              prefixLength = e.snd.ipv6.cidr;
            }
          ];
        };
      })
      (
        builtins.filter (e: !builtins.hasAttr "untagged" e.snd) (
          lib.lists.zipLists (builtins.attrNames lan) (builtins.attrValues lan)
        )
      )
    )
    ++ [
      # Untagged (native) VLAN
      {
        name = lan_iface;
        value = {
          useDHCP = false;
          ipv4.addresses = [
            {
              address = untagged_lan_attrs.ipv4.address;
              prefixLength = untagged_lan_attrs.ipv4.cidr;
            }
          ];
          ipv6.addresses = [
            {
              address = untagged_lan_attrs.ipv6.address;
              prefixLength = untagged_lan_attrs.ipv6.cidr;
            }
          ];
        };
      }
    ]
  );
}
