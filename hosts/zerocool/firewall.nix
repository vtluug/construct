{ lan_iface }:
{
  networking.nftables.enable = true;
  networking.firewall = {
    enable = true;
    allowPing = true;
    trustedInterfaces = [ lan_iface ];
  };
}
