{
  lib,
  role ? "agent",
  clusterInit ? false,
  serverAddr ? "10.98.3.2",
  flannelIface ? "enp1s0f1",
}:
{
  networking.firewall.allowedTCPPorts = [
    6443
  ];

  networking.firewall.allowedUDPPorts = [
    8472
  ];

  services.k3s = {
    inherit role clusterInit;

    enable = true;
    serverAddr = lib.mkIf (role != "server") "https://${serverAddr}:6443";
    nodeIP = lib.mkIf (role == "server") serverAddr;

    extraFlags = [
      "--token=\"garbage secret\""
    ]
    ++ lib.optionals (role == "server") [
      "--kubelet-arg=node-ip=${serverAddr}"
      "--flannel-iface=${flannelIface}"
      "--advertise-address=${serverAddr}"
      "--bind-address=${serverAddr}"
      "--write-kubeconfig-mode=0640"
      "--write-kubeconfig-group=wheel"
    ];
    extraKubeletConfig = lib.mkIf (role == "server") {
      address = serverAddr;
    };
  };
}
