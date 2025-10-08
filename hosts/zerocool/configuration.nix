{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ../common/nix.nix
      ../common/sshd.nix
      ../common/users-local.nix
      ../common/tz-locale.nix
    ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  networking.hostName = "zerocool";

  system.stateVersion = "25.05";
}

