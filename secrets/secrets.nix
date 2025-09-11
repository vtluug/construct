let
  vesuvius = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOHI7ziwxkEbJzvpaZulPFpDW7l0vbGJ+ifHcHJ2fHex";
in {
  "krb5.keytab.age".publicKeys = [ vesuvius ];
}
