{ lan_iface, dhcp_start, dhcp_end }:
let
  hosts = import ./static-hosts.nix;
  dnsmasq-hosts = builtins.map (host:
  "${host.mac},${host.ipv4},${host.name}"
  ) hosts;
in
{
  services.dnsmasq = {
    enable = true;
    settings = {
      interface = lan_iface;
      dhcp-range = [
        "${dhcp_start},${dhcp_end},12h"
        "10.98.4.2,static,255.255.255.0"
      ];
      "dhcp-host" = dnsmasq-hosts;
    };
  };
}