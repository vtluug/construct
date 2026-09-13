let
  backbiter = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH0gfTT0htiRipP8kD4/IM88mEPoqUHYrMstE/CohYnE backbiter host key";
  excalibur = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII8U2YHuRDBTGAx8d/bF/PB1bzDi+0EEBnL/3Gs34dnt excalibur host key";
  eyelander = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKTeMkC8h0ldLsj6gbEOPuiuHYMJCxlheA3VlhUTY5bi eyelander host key";
  gram = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIElJZbUbIZ3NPMaFxIjyAli8ovw5qLzi2UpjdsbT3lWs gram host key";
  gryffindor = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEQtyGqx03N/FOl5eZ/WOQUbigTMUpAdzH6syM4CgRBF gryffindor host key";
  kusanagi = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILxvL/dhDeuKKanBmpmyFWjFkRQAUrv6MLiNPGrH7njM kusanagi host key";
  narsil = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIVI2ZfEf91h4Yf1fq6zP8TGQWMawhVS5KNpCAMw3KJp narsil host key";
  oathbringer = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIACjyeJhbFU3ma10jmx2GsvLavzv7FUA4fjhslPR+kwk oathbringer host key";
  riptide = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMRZkEj+3cM3exRKVMGgUctEwzBhKYy0YfhpUlJdLt/k riptide host key";
  sting = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDkqbbxl99jQCHj4P3/C+7MLVHxBMswZ0V7fmHpAv25C sting host key";
  vesuvius = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOHI7ziwxkEbJzvpaZulPFpDW7l0vbGJ+ifHcHJ2fHex";
  zerocool = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN+60yHIqES3Dr1Upp23QGwzvqELQEeH6e4lTKTV9iUY root@zerocool";
in {
  "k3s-join-token.age".publicKeys = [
    backbiter
    excalibur
    eyelander
    gram
    gryffindor
    kusanagi
    narsil
    oathbringer
    riptide
    sting
    vesuvius
  ];
  "blade-hosts/backbiter/k3s-node-password.age".publicKeys = [ backbiter ];
  "blade-hosts/excalibur/k3s-node-password.age".publicKeys = [ excalibur ];
  "blade-hosts/eyelander/k3s-node-password.age".publicKeys = [ eyelander ];
  "blade-hosts/gram/k3s-node-password.age".publicKeys = [ gram ];
  "blade-hosts/gryffindor/k3s-node-password.age".publicKeys = [ gryffindor ];
  "blade-hosts/kusanagi/k3s-node-password.age".publicKeys = [ kusanagi ];
  "blade-hosts/narsil/k3s-node-password.age".publicKeys = [ narsil ];
  "blade-hosts/oathbringer/k3s-node-password.age".publicKeys = [ oathbringer ];
  "blade-hosts/riptide/k3s-node-password.age".publicKeys = [ riptide ];
  "blade-hosts/sting/k3s-node-password.age".publicKeys = [ sting ];
  "keytabs/vesuvius.keytab.age".publicKeys = [ vesuvius ];
  "zerocool/wg.priv.age".publicKeys = [ zerocool ];
  "vesuvius/gandi.env.age".publicKeys = [ vesuvius ];
}
