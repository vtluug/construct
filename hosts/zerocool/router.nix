{ wan_iface, wg_iface, lan_iface, lan, ... }:
{
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = true;
    "net.ipv6.conf.all.forwarding" = true;
  };

  networking.nat = {
    enable = true;
    externalInterface = wan_iface;
    internalInterfaces = [ lan_iface wg_iface ] ++ builtins.map (vlanid: "vlan${vlanid}" ) (builtins.attrNames lan);
  };
}
