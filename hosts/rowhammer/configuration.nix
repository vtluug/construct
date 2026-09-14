{ config, lib, pkgs, ... }:
{
  imports =
    [
      ./hardware-configuration.nix
      ./nvidia.nix
      ./packages.nix
      ../common/nix.nix
      ../common/packages.nix
      ../common/sshd.nix
      ../common/users-local.nix
      ../common/tz-locale.nix
    ];

  networking.hostName = "rowhammer";

  networking.networkmanager.enable = true;

  system.stateVersion = "25.11";
}
