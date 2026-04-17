{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    cmake
    gdb
    gcc
  ];
}
