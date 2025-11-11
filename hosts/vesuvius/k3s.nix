{ ... }: {
  imports = [
    ../common/k3s.nix
  ];

  services.k3s = {
    role = "server";
    clusterInit = true;
  };
}
