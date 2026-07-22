{ modulesPath, pkgs, lib, ... }: {
  imports = [
    ./eno1-imm-disable.nix
    (import ../common/k3s.nix { inherit lib; })
    ../common/nix.nix
    ../common/sshd.nix
    ../common/users-local.nix
    (modulesPath + "/installer/netboot/netboot-minimal.nix")
  ];

  # Get NFS working (not idea why it's not default in NixOS)
  boot.initrd = {
    supportedFilesystems = [ "nfs" ];
    kernelModules = [ "nfs" ];
  };

  # Get hostname from DHCP request
  networking.hostName = "";

  # Open kubernetes' ports for flannel and API server
  networking.firewall = {
    allowedTCPPorts = [
      6443
      10250
    ];
    allowedUDPPorts = [
      8472
    ];
  };


  # when making the ISO, the initialHashedPassword is set to "" for some reason
  # we already set a hashed password, so null this
  users.users.root.initialHashedPassword = lib.mkForce null;

  environment.systemPackages = with pkgs; [
    fastfetch
    git
    nfs-utils
  ];

  system.stateVersion = "25.11";
}
