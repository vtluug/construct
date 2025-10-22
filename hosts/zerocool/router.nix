{ wan_gateway, wan_iface, wan_addr, wan_cidr, lan_iface, lan_addr, lan_cidr, wg_iface, ... }:
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
  networking.defaultGateway = wan_gateway;
  networking.interfaces = {
    "${wan_iface}" = {
      ipv4.addresses = [
        {
          address = wan_addr;
          prefixLength = wan_cidr;
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
