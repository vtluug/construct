{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    (import ../common/k3s.nix { role = "server"; clusterInit = true; })
    ./nix.nix
    ./zfs.nix
    ./ipa.nix
    ./netboot.nix

    ../common/nfs.nix
    ../common/tz-locale.nix
    ../common/users-local.nix
    ../common/sshd.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "vesuvius";

  networking.networkmanager.enable = true;
  networking.networkmanager.unmanaged = [ "interface-name:enp1s0f1" ];

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    neovim
  ];

  system.stateVersion = "25.05"; # Did you read the comment?
}
