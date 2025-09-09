{ pkgs, ... }:
{
  boot.supportedFilesystems = [ "zfs" ];

  environment.systemPackages = [ pkgs.zfs ];

  networking.hostId = "eaab8b4b";

  systemd.services.zfs-mount.enable = false;

  services.zfs.autoScrub.enable = true;

  fileSystems."/mount/forge" = {
    device = "forge";
    fsType = "zfs";
  };
}
