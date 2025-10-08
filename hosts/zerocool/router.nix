{ wan_iface, lan_iface, lan_addr, wg_iface, ... }:
{
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = true;
  };
  networking.nat = {
    enable = true;
    externalInterface = wan_iface;
    internalInterfaces = [ lan_iface wg_iface ];
  };

  networking.useDHCP = false;
  networking.interfaces = {
    "${wan_iface}" = {
      useDHCP = true;
    };
    "${lan_iface}" = {
      ipv4.addresses = [
        {
          address = lan_addr;
          prefixLength = 22;
        }
      ];
    };
  };
}
