# TODO: /etc/krb5.keytab missing, maybe agenix
{ pkgs, ... }:
{
  security.ipa = {
    enable = true;

    server = "chimera.vtluug.org";
    domain = "krb.vtluug.org";
    realm = "KRB.VTLUUG.ORG";

    basedn = "dc=krb,dc=vtluug,dc=org";

    certificate = pkgs.fetchurl {
      url = http://chimera.vtluug.org/ipa/config/ca.crt;
      sha256 = "16wv6kfvnm0hcyzr0wjrgmymw3asm84m8r1wbfq09qvqrjycfc6s";
    };
  };
}
