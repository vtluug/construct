{ pkgs, ... }:
{
  boot.supportedFilesystems = [ "zfs" ];

  environment.systemPackages = [ pkgs.zfs ];

  networking.hostId = "eaab8b4b";

  systemd.services.zfs-mount.enable = false;

  services.zfs.autoScrub.enable = true;

  fileSystems."/forge" = {
    device = "forge";
    fsType = "zfs";
    neededForBoot = true;
  };

  fileSystems."/nix" = {
    device = "/forge/nix";
    fsType = "none";
    options = [ "bind" ];
    depends = [ "/forge" ];
  };
}
