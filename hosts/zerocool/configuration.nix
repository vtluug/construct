{ config, lib, pkgs, ... }:
let
  wan_iface = "enp3s0f0";
  wan = {
    ipv4 = {
      gateway = "198.82.185.129";
      address = "198.82.185.170";
      cidr = 22;
    };
    ipv6 = {
      gateway = "2001:468:c80:6119::1";
      address = "2001:468:c80:6119:82c1:6eff:fe21:2b88";
      cidr = 60;
    };
  };

  wg_iface  = "wg0";

  lan_iface = "enp3s0f1";
  lan = {
    # Static hosts
    "10" = {
      ipv4 = {
        address = "10.98.4.1";
        cidr = 24;
      };
      ipv6 = {
        address = "2607:b400:6:ce80::1";
        cidr = 64;
      };
    };
    # Dynamic host
    "20" = {
      ipv4 = {
        address = "10.98.5.1";
        cidr = 24;
      };
      ipv6 = {
        address = "2607:b400:6:ce81::1";
        cidr = 64;
      };
    };
    # Co-location stuff
    "30" = {
      ipv4 = {
        address = "10.98.6.1";
        cidr = 24;
      };
      ipv6 = {
        address = "2607:b400:6:ce82::1";
        cidr = 64;
      };
    };
    # Management
    "40" = {
      ipv4 = {
        address = "10.98.7.1";
        cidr = 24;
      };
      ipv6 = {
        address = "2607:b400:6:ce83::1";
        cidr = 64;
      };
    };
  };
in
{
  imports =
    [
      ./hardware-configuration.nix
      ../common/nix.nix
      ../common/sshd.nix
      ../common/users-local.nix
      ../common/tz-locale.nix

      ./dns.nix
      (import ./router.nix {
        inherit wan_iface wg_iface lan_iface lan;
      })
      (import ./lan.nix {
        inherit lib lan_iface lan;
      })
      (import ./wan.nix {
        inherit wan_iface wan;
      })
      (import ./firewall.nix {
        inherit lan_iface;
      })
      (import ./dhcp.nix {
        inherit lan_iface;
        dhcp_start = "10.98.5.1";
        dhcp_end = "10.98.5.127";
      })
      (import ./wireguard.nix {
        inherit config wg_iface;
      })
    ];

  networking.hostName = "zerocool";
  system.stateVersion = "25.05";
}

