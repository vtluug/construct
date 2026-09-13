let
  eyelander = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKTeMkC8h0ldLsj6gbEOPuiuHYMJCxlheA3VlhUTY5bi eyelander host key";
  vesuvius = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOHI7ziwxkEbJzvpaZulPFpDW7l0vbGJ+ifHcHJ2fHex";
  zerocool = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN+60yHIqES3Dr1Upp23QGwzvqELQEeH6e4lTKTV9iUY root@zerocool";
in {
  "k3s-join-token.age".publicKeys = [
    eyelander
    vesuvius
  ];
  "blade-hosts/eyelander/k3s-node-password.age".publicKeys = [ eyelander ];
  "keytabs/vesuvius.keytab.age".publicKeys = [ vesuvius ];
  "zerocool/wg.priv.age".publicKeys = [ zerocool ];
  "vesuvius/gandi.env.age".publicKeys = [ vesuvius ];
}
