{ config, pkgs, ... }:
let
  mkNfs = {path, options ? [ "vers=4.0" "soft" "nodev" "nosuid" ]}: {
    device = "${path}";
    fsType = "nfs";
    inherit options;
  };
in
{
  environment.systemPackages = [ pkgs.nfs-utils ];

  fileSystems."/nfs/cistern/share" = mkNfs {path = "10.98.0.7:/cistern/nfs/share";};
  fileSystems."/nfs/cistern/files" = mkNfs {path = "10.98.0.7:/cistern/nfs/files";};
  fileSystems."/nfs/cistern/home" = mkNfs {
    path = "10.98.0.7:/cistern/nfs/home";
    options = [ "vers=4.0" "soft" "nodev" "nosuid" ];
  };
  fileSystems."/nfs/cistern/libvirt" = mkNfs {path = "10.98.0.7:/cistern/nfs/libvirt";};
  fileSystems."/nfs/cistern/docker/data" = mkNfs {path = "10.98.0.7:/cistern/nfs/docker/data";};
}