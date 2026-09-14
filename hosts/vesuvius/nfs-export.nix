{
  services.nfs.server = {
    enable = true;
    exports = ''
      /forge/nfs              10.98.0.0/16(rw,sync,fsid=root,no_subtree_check,root_squash,sec=sys) 2607:b400:0006:cc80::/64(rw,sync,fsid=root,no_subtree_check,root_squash,sec=sys) 
      /forge/nfs/kube-volumes 10.98.3.0/24(rw,sync,no_root_squash,insecure,no_subtree_check)
    '';

    # fixed rpc.statd port; for firewall
    lockdPort = 4001;
    mountdPort = 4002;
    statdPort = 4000;
  };
  systemd.services."rpc-svcgssd".enable = false;

  networking.firewall = {
    enable = true;
    # for NFSv3; view with `rpcinfo -p`
    allowedTCPPorts = [
      111
      2049
      4000
      4001
      4002
    ];
    allowedUDPPorts = [
      111
      2049
      4000
      4001
      4002
    ];
  };
}
