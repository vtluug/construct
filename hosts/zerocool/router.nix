{ wan_iface, lan_iface, lan_addr, lan_cidr, wg_iface, ... }:
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
  networking.defaultGateway = "198.82.185.129";
  networking.interfaces = {
    "${wan_iface}" = {
      ipv4.addresses = [
        {
          address = "198.82.185.170";
          prefixLength = 22;
        }
      ];
    };
    "${lan_iface}" = {
      ipv4.addresses = [
        {
          address = lan_addr;
          prefixLength = lan_cidr;
        }
      ];
    };
  };
}
