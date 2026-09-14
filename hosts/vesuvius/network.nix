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
  networking.tempAddresses = "disabled";
  networking.networkmanager.settings.connection."ipv6.addr-gen-mode" = 0; # eui64
  networking.networkmanager.unmanaged = [ "interface-name:ens865" ];

  # statically routed k3s backend
  networking.interfaces.ens865 = {
    useDHCP = false;
  };
  networking.macvlans.ens865-shim = {
    interface = "ens865";
    mode = "bridge";
  };

  networking.interfaces.ens865-shim = {
    useDHCP = false;
    ipv4.addresses = [{
      address = "10.98.3.1";
      prefixLength = 24;
    }];
  };

  # so k3s sets this itself when it initializes, but
  #  nix then (sometimes) overwrites it on rebuild. so
  #  here we set it explicitly
  boot.kernel.sysctl."net.ipv4.conf.all.forwarding" = 1;

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
    flushRuleset = false;
    extraDeletions = ''
      add table ip6 filter
      add chain ip6 filter input
      delete chain ip6 filter input
    '';
    ruleset = ''
        table ip6 filter {
          chain input {
            type filter hook input priority 0; policy drop;

            ct state { established, related } accept;
            iifname "lo" accept;
            tcp dport 2222 accept comment "Allow global IPv6 SSH";

            icmpv6 type { destination-unreachable, packet-too-big, time-exceeded, parameter-problem, nd-neighbor-solicit, nd-neighbor-advert } accept;

            ip6 saddr ${ipv6_allowed_prefix} accept comment "Allow  IPv6 from LAN";
            ip6 saddr fe80::/64 accept comment "Allow  IPv6 from link local";
          }
        }
      '';
  };
}
