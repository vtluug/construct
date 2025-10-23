{ ... }: {
  imports = [
    ../common/k3s-ports.nix
  ];

  services.k3s = {
    enable = true;
    role = "server";
    token = "garbage secret";
    clusterInit = true;
  };
}
