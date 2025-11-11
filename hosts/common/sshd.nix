{ config, pkgs, ... }:
{
  services.openssh = {
    enable = true;
    ports = [22 2222];
  };
}
