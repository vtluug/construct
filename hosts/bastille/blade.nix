{ modulesPath, pkgs, lib, ... }: {
  imports = [
    (import ../common/k3s.nix {})
    ../common/nix.nix
    ../common/sshd.nix
    ../common/users-local.nix
    (modulesPath + "/installer/netboot/netboot-minimal.nix")
  ];

  # when making the ISO, the initialHashedPassword is set to "" for some reason
  # we already set a hashed password, so null this
  users.users.root.initialHashedPassword = lib.mkForce null;

  environment.systemPackages = [
    pkgs.fastfetch
  ];

  system.stateVersion = "25.11";
}
