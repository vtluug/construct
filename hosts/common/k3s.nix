{
  lib,
  role ? "agent",
  clusterInit ? false,
  serverAddr ? "10.98.3.1",
  flannelIface ? "enp1s0f1",
}:
{
  networking.firewall.allowedTCPPorts = [
    6443
  ];

  networking.firewall.allowedUDPPorts = [
    8472
  ];

  age.secrets."k3s-join-token".file = ../../secrets/k3s-join-token.age;

  services.k3s = {
    inherit role clusterInit;

    enable = true;
    serverAddr = lib.mkIf (role != "server") "https://${serverAddr}:6443";
    nodeIP = lib.mkIf (role == "server") serverAddr;
    tokenFile = "/run/agenix/k3s-join-token";

    extraFlags = [
      "--flannel-iface=${flannelIface}"
    ] ++ lib.optionals (role == "server") [
      "--advertise-address=${serverAddr}"
      "--bind-address=${serverAddr}"
      "--tls-san=${serverAddr}"
      "--write-kubeconfig-mode=0640"
      "--write-kubeconfig-group=wheel"
    ];
  };
}
