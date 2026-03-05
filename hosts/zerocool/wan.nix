{ wanIface, wan, ... }:
{
  networking.defaultGateway = wan.ipv4.gateway;
  networking.defaultGateway6 = {
    address = wan.ipv6.gateway;
    interface = wanIface;
  };

  networking.interfaces = {
    "${wanIface}" = {
      useDHCP = false;
      proxyARP = true;
      ipv4.addresses = [
        {
          address = wan.ipv4.address;
          prefixLength = wan.ipv4.cidr;
        }
      ];
      ipv6.addresses = [
        {
      	  address = wan.ipv6.address;
      	  prefixLength = wan.ipv6.cidr;
        }
      ];
    };
  };
}
