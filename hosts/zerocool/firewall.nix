{ lan_iface }:
{
  networking.firewall = {
    enable = true;
    allowPing = true;
    trustedInterfaces = [ lan_iface ];
    allowedTCPPorts = [ 22 2222 ]; # ssh
    allowedUDPPorts = [ 51820 ]; # wg
  };
}
