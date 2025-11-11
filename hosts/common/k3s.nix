{ role ? "agent", clusterInit ? false }: {
  networking.firewall.allowedTCPPorts = [
    6443
  ];

  networking.firewall.allowedUDPPorts = [
    8472
  ];

  services.k3s = {
    inherit role clusterInit;

    enable = true;
    token = "garbage secret";
    serverAddr = "https://10.98.1.147:6443";
  };
}
