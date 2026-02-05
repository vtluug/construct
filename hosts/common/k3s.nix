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
    token = "garbage secret";
    serverAddr = lib.mkIf (role != "server") "https://${serverAddr}:6443";
    extraFlags = lib.mkIf (role == "server") [
      "--flannel-iface=${flannelIface}"
      "--node-ip=${serverAddr}"
      "--advertise-address=${serverAddr}"
      "--bind-address=${serverAddr}"
    ];
  };
}
