{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    cmake
    distrobox
    gdb
    gcc
  ];
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };
}
