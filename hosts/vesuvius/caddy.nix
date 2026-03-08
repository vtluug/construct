{
  config,
  pkgs,
  lib,
  ...
}:
let
  gandi-key-path = "/secrets/gandi.env";
in
{
  age.secrets."gandi.env".file = ../../secrets/vesuvius/gandi.env.age;

  containers.caddy-proxy = {
    autoStart = true;
    ephemeral = true;
    macvlans = [ "eno0" ];
    privateNetwork = false;
    bindMounts = {
      "${gandi-key-path}" = {
        hostPath = config.age.secrets."gandi.env".path;
      };
      "/var/lib/caddy" = {
        hostPath = "/var/lib/caddy";
        isReadOnly = false;
      };
    };
    config =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        networking.interfaces.mv-eno0 = {
          useDHCP = true;
          ipv4.addresses = [
            {
              address = "128.173.89.163";
              prefixLength = 24;
            }
          ];
          ipv6.addresses = [
            {
              address = "2607:b400:6:cc80:0:aff:fe62:f";
              prefixLength = 64;
            }
          ];
        };

        # Force container to get DNS settings from network
        networking.useHostResolvConf = false;

        services.caddy = {
          enable = true;
          virtualHosts."*.vtluug.org".extraConfig = ''
            reverse_proxy https://svc.bastille.vtluug.org:443 {
              transport http {
                tls_insecure_skip_verify
              }
            }
          '';
          package = pkgs.caddy.withPlugins {
            plugins = [ "github.com/caddy-dns/gandi@v1.1.0" ];
            hash = "sha256-5mjD0CY7f5+sRtV1rXysj8PvId2gQaWiXlIaTg2Lv8A=";
          };
          globalConfig = ''
            acme_dns gandi {env.GANDI_AUTH_TOKEN}
          '';
        };
        systemd.services.caddy.serviceConfig.EnvironmentFile = [ "${gandi-key-path}" ];

        networking.firewall = {
          allowedTCPPorts = [
            80
            443
          ];
          allowedUDPPorts = [
            80
            443
          ];
        };

        system.stateVersion = "26.05";
      };
  };
}
