# TODO: /etc/krb5.keytab missing, maybe agenix
{ config, pkgs, ... }:
{
  age.secrets."krb5.keytab" = {
    file = ../../secrets/keytabs/vesuvius.keytab.age;
    path = "/etc/krb5.keytab";
    owner = "root";
    group = "root";
    mode = "0600";
  };
  environment.variables.KRB5_KTNAME = config.age.secrets."krb5.keytab".path;

  networking.domain = "vtluug.org";

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
  security.sudo.extraRules = [
    {
      groups = [ "sudoers" ];
      commands = [
        {
          command = "ALL";
          options = [ "SETENV" ];
        }
      ];
    }
  ];
}
