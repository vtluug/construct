{
  config,
  lib,
  pkgs,
  ipv6_allowed_prefix ? "2607:b400:6:cc80::/64",
  ...
}:
{
  networking.hostName = "vesuvius";

  networking.networkmanager.enable = true;
  networking.networkmanager.unmanaged = [ "interface-name:enp1s0f1" ];

  networking.interfaces.enp1s0f1.ipv4.routes = [
    {
      address = "10.98.0.0";
      prefixLength = 16;
      via = "10.98.3.1";
    }
  ];

  # Open ports for K3s ingress
  networking.firewall = {
    allowedTCPPorts = [
      80
      443
    ];
    allowedUDPPorts = [
      80
      443
    ];
  };


  networking.nftables = {
    enable = true;
    ruleset = ''
        table ip6 filter {
          chain input {
            type filter hook input priority 0; policy drop;

            ct state { established, related } accept;
            iifname "lo" accept;

            icmpv6 type { destination-unreachable, packet-too-big, time-exceeded, parameter-problem, nd-neighbor-solicit, nd-neighbor-advert } accept;

            ip6 saddr ${ipv6_allowed_prefix} accept comment "Allow  IPv6 from LAN";
            ip6 saddr fe80::/64 accept comment "Allow  IPv6 from link local";
          }
        }
      '';
  };
}
