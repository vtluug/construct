{
  services.nfs.server.enable = true;
  services.nfs.server.exports = ''
    /forge/kube-volumes 10.98.3.0/24(rw,async,no_subtree_check)
  '';
}
