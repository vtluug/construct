{
  config,
  lib,
  pkgs,
  ...
}:
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

  wg_iface = "wg0";

  lan_iface = "enp3s0f1";
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
      allow_router_access = true;
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
      allow_router_access = true;
      untagged = true;
      dhcpv4 = "10.98.5.128,10.98.5.254,12h";
      dhcpv6 = "ra-stateless,ra-names,12h";
    };
    # General Hosts
    "30" = {
      ipv4 = {
        address = "10.98.6.1";
        cidr = 24;
      };
      ipv6 = {
        address = "2607:b400:6:ce82::1";
        cidr = 64;
      };
      allow_router_access = true;
      dhcpv4 = "10.98.6.128,10.98.6.254,12h";
      dhcpv6 = "ra-stateless,ra-names,12h";
    };
    # Co-location
    "40" = {
      ipv4 = {
        address = "10.98.7.1";
        cidr = 24;
      };
      ipv6 = {
        address = "2607:b400:6:ce83::1";
        cidr = 64;
      };
      allow_router_access = false;
      dhcpv4 = "10.98.7.128,10.98.7.254,12h";
      dhcpv6 = "ra-stateless,ra-names,12h";
    };
  };

  check_untagged = lib.asserts.assertMsg (
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
      inherit lib lan_iface lan;
    })
    (import ./dhcp.nix {
      inherit lib lan_iface lan;
    })
    (import ./wan.nix {
      inherit wan_iface wan;
    })
    (import ./firewall.nix {
      inherit
        lib
        lan_iface
        lan
        wan_iface
        wan
        wg_iface
        ;
    })
    (import ./wireguard.nix {
      inherit config wg_iface;
    })
  ];

  networking.hostName = "zerocool";
  system.stateVersion = "25.05";
}
