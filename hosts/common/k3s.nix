{ ... }: {
  imports = [
    ./k3s-ports.nix
  ];

  services.k3s = {
    enable = true;
    role = "agent";
    token = "garbage secret";
    serverAddr = "https://10.98.1.147:6443";
  };
}
