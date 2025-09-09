{ pkgs, ... }:
{
  boot.supportedFilesystems = [ "zfs" ];

  environment.systemPackages = [ pkgs.zfs ];

  networking.hostId = "eaab8b4b";
}
