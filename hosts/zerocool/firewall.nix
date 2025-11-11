{ lan_iface }:
{
  networking.firewall = {
    enable = true;
    allowPing = true;
    trustedInterfaces = [ lan_iface ];
    allowedUDPPorts = [ 51820 ]; # wg
  };
}
