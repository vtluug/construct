{
  config,
  lib,
  pkgs,
  ...
}:
let
  wanIface = "enp3s0f0";
  wan = {
    ipv4 = {
      gateway = "198.82.185.129";
      address = "198.82.185.170";
      cidr = 22;
    };
    ipv6 = {
      gateway = "2001:468:c80:6119::1";
      address = "2001:468:c80:6119:82c1:6eff:fe21:2b88";
      cidr = 64;
    };
    tcpPorts = [
      22
      2222
    ];
    udpPorts = [ 51820 ];
    # Publicly routable IPv4 addresses only
    exposeIpv4Hosts = [
      # Scaryterry
      "198.82.185.171"
      # Alex's box
      "198.82.185.174"
    ];
    # Publicly routable IPv6 addresses only
    exposeIpv6Hosts = [
      # Scaryterry
      "2607:b400:6:ce82:0:aff:fe62:f"
      # Alex's box
      "2607:b400:6:ce83:225:90ff:fe9b:ed30"
    ];
  };

  wgIface = "wg0";

  lanIface = "enp3s0f1";
  lan = {
    # Management
    "10" = {
      ipv4 = {
        address = "10.98.4.1";
        cidr = 24;
      };
      ipv6 = {
        address = "2607:b400:6:ce80::1";
        cidr = 64;
      };
      allowRouterAccess = true;
      domain = "mgmt";
      dhcpv4 = "10.98.4.128,10.98.4.254,12h";
      dhcpv6 = "ra-stateless,ra-names,12h";
    };
    # Untagged (native) VLAN Internal Traffic
    "20" = {
      ipv4 = {
        address = "10.98.5.1";
        cidr = 24;
      };
      ipv6 = {
        address = "2607:b400:6:ce81::1";
        cidr = 64;
      };
      allowRouterAccess = true;
      untagged = true;
      domain = "internal";
      dhcpv4 = "10.98.5.128,10.98.5.254,12h";
      dhcpv6 = "ra-stateless,ra-names,12h";
    };
    # General Hosts
    "30" = {
      ipv4 = {
        address = "10.98.6.1";
        cidr = 24;
        # IPv4 hosts for ARP proxy
        publicHosts = [
          # Scaryterry
          "198.82.185.171"
        ];
      };
      ipv6 = {
        address = "2607:b400:6:ce82::1";
        cidr = 64;
      };
      allowRouterAccess = true;
      domain = "g";
      dhcpv4 = "10.98.6.128,10.98.6.254,12h";
      dhcpv6 = "ra-stateless,ra-names,12h";
    };
    # Co-location
    "40" = {
      ipv4 = {
        address = "10.98.7.1";
        cidr = 24;
        # IPv4 hosts for ARP proxy
        publicHosts = [
          # Alex's box
          "198.82.185.174"
        ];
      };
      ipv6 = {
        address = "2607:b400:6:ce83::1";
        cidr = 64;
      };
      allowRouterAccess = false;
      domain = "colo";
      dhcpv4 = "10.98.7.128,10.98.7.254,12h";
      dhcpv6 = "ra-stateless,ra-names,12h";
    };
  };

  checkUntagged = lib.asserts.assertMsg (
    builtins.length (
      builtins.filter (e: builtins.hasAttr "untagged" e.snd) (
        lib.lists.zipLists (builtins.attrNames lan) (builtins.attrValues lan)
      )
    ) == 1
  ) "There must be exactly one untagged VLAN for LAN" lan;
in
{
  imports = [
    ./hardware-configuration.nix
    ../common/nix.nix
    ../common/sshd.nix
    ../common/users-local.nix
    ../common/tz-locale.nix

    ./dns.nix
    ./router.nix
    (import ./lan.nix {
      inherit lib lanIface lan;
    })
    (import ./dhcp.nix {
      inherit lib lanIface lan;
    })
    (import ./wan.nix {
      inherit wanIface wan;
    })
    (import ./firewall.nix {
      inherit
        lib
        lanIface
        lan
        wanIface
        wan
        wgIface
        ;
    })
    (import ./wireguard.nix {
      inherit config wgIface;
    })
  ];

  environment.systemPackages = with pkgs; [
    neovim
    helix
    mtr
    dig
    tcpdump
    ndisc6
    inetutils
  ];

  networking.hostName = "zerocool";
  system.stateVersion = "25.05";
}
