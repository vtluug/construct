{ config, lib, pkgs, ... }:
let
  wan_iface = "enp3s0f0";
  lan_iface = "enp3s0f1";
  wg_iface  = "wg0";
  lan_addr  = "10.98.4.1";
  lan_cidr  = 22;
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
        inherit wan_iface lan_iface lan_addr lan_cidr wg_iface;
        wan_gateway = "198.82.185.129";
        wan_addr = "198.82.185.170";
        wan_cidr = 22;
        wan_addr6 = "2001:468:c80:6119:82c1:6eff:fe21:2b88";
        wan_cidr = 64;
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

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  networking.hostName = "zerocool";

  system.stateVersion = "25.05";
}

