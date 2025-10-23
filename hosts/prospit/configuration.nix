{ modulesPath, pkgs, ... }: {
  imports = [
    ../common/k3s.nix
    ../common/nix.nix
    ../common/sshd.nix
    ../common/users-local.nix
    (modulesPath + "/installer/netboot/netboot-minimal.nix")
  ];

  environment.systemPackages = [
    pkgs.fastfetch
  ];

  system.stateVersion = "25.11";
}
