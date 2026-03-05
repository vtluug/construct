{
  lib,
  lanIface,
  lan,
  ...
}:
let
  untaggedVlan = lib.lists.findFirst (
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
          interface = lanIface;
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
        name = lanIface;
        value = {
          useDHCP = false;
          ipv4.addresses = [
            {
              address = untaggedVlan.ipv4.address;
              prefixLength = untaggedVlan.ipv4.cidr;
            }
          ];
          ipv6.addresses = [
            {
              address = untaggedVlan.ipv6.address;
              prefixLength = untaggedVlan.ipv6.cidr;
            }
          ];
        };
      }
    ]
  );
}
