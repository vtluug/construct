{ modulesPath, pkgs, ... }: {
  imports = [
    ../common/users-local.nix
    ../common/nix.nix
    ../common/sshd.nix
    (modulesPath + "/installer/netboot/netboot-minimal.nix")
  ];

  environment.systemPackages = [
    pkgs.fastfetch
  ];

  system.stateVersion = "25.11";
}
