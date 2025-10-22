let
  vesuvius = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOHI7ziwxkEbJzvpaZulPFpDW7l0vbGJ+ifHcHJ2fHex";
  zerocool = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN+60yHIqES3Dr1Upp23QGwzvqELQEeH6e4lTKTV9iUY root@zerocool";
in {
  "krb5.keytab.age".publicKeys = [ vesuvius ];
  "zerocool/wg.priv.age".publicKeys = [ zerocool ];
}
