{ wan_iface, lan_iface, wg_iface, ... }:
{
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = true;
    "net.ipv6.conf.all.forwarding" = true;
  };

  networking.nat = {
    enable = true;
    externalInterface = wan_iface;
    internalInterfaces = [ lan_iface wg_iface ];
  };
}
