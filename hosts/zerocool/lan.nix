{
  lib,
  lan_iface,
  lan,
  ...
}:
{
  networking.vlans = builtins.listToAttrs (
    builtins.map (vlanid: {
      name = "vlan${vlanid}";
      value = {
        id = builtins.fromJSON vlanid;
        interface = lan_iface;
      };
    }) (builtins.attrNames lan)
  );

  # recursiveUpdate appends generated interface attrset with existing one to avoid overwriting existing configuration
  networking.interfaces = builtins.listToAttrs (
    builtins.map (e: {
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
    }) (lib.lists.zipLists (builtins.attrNames lan) (builtins.attrValues lan))
  );
}
