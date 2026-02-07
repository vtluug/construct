{ config, pkgs, lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    (import ../common/k3s.nix { inherit lib; role = "server"; clusterInit = true; })
    ./nix.nix
    ./zfs.nix
    ./ipa.nix
    ./netboot.nix
    ./nfs-export.nix
    (import ./network.nix { inherit config lib pkgs; })

    ../common/nfs.nix
    ../common/tz-locale.nix
    ../common/users-local.nix
    ../common/sshd.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    git
    neovim
  ];

  system.stateVersion = "25.05"; # Did you read the comment?
}
