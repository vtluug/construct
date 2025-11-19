{ wan_gateway, wan_gateway6, wan_iface, wan_addr, wan_cidr, wan_addr6, wan_cidr6, lan_iface, lan_addr, lan_cidr, wg_iface, ... }:
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

  networking.useDHCP = false;
  networking.defaultGateway = wan_gateway;
  networking.defaultGateway6 = {
    address = wan_gateway6;
    interface = wan_iface;
  };
  networking.interfaces = {
    "${wan_iface}" = {
      ipv4.addresses = [
        {
          address = wan_addr;
          prefixLength = wan_cidr;
        }
      ];
      ipv6.addresses = [
        {
      	  address = wan_addr6;
      	  prefixLength = wan_cidr6;
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
