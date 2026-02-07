{
  config,
  lib,
  pkgs,
  public_ipv4 ? "128.173.89.163",
  public_ipv4_prefix_length ? 24,
  public_ipv6 ? "2607:b400:6:cc80:0:aff:fe62:f",
  public_ipv6_prefix_length ? 64,
  ipv6_allowed_prefix ? "2607:b400:6:cc80::/64",
  ...
}:
{
  networking.hostName = "vesuvius";

  networking.networkmanager.enable = true;
  networking.networkmanager.unmanaged = [ "interface-name:enp1s0f1" ];

  networking.interfaces.eno0 = {
    useDHCP = true;
    ipv4.addresses = [
      {
        address = public_ipv4;
        prefixLength = public_ipv4_prefix_length;
      }
    ];
    ipv6.addresses = [
      {
        address = public_ipv6;
        prefixLength = public_ipv6_prefix_length;
      }
    ];
  };

  networking.interfaces.enp1s0f1.ipv4.routes = [
    {
      address = "10.98.0.0";
      prefixLength = 16;
      via = "10.98.3.1";
    }
  ];

  networking.nftables = {
    enable = true;
    ruleset = ''
        table ip filter {
          chain input {
            type filter hook input priority 0; 

            ip daddr ${public_ipv4} tcp dport { 22, 80, 443 } accept;
            ip daddr ${public_ipv4} drop;
          }
        }

        table ip6 filter {
          chain input {
            type filter hook input priority 0;

            ct state { established, related } accept;
            iifname "lo" accept;

            icmpv6 type { destination-unreachable, packet-too-big, time-exceeded, parameter-problem, nd-neighbor-solicit, nd-neighbor-advert } accept;

            ip6 daddr ${public_ipv6} tcp dport { 22, 80, 443 } accept;
            ip6 saddr ${ipv6_allowed_prefix} accept;
            policy drop;
          }
        }
      '';
  };
}
