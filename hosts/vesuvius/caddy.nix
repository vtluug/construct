{
  config,
  pkgs,
  lib,
  ...
}:
{
  age.secrets."gandi.env".file = ../../secrets/vesuvius/gandi.env.age;

  containers.caddy-proxy = {
    autoStart = true;
    ephemeral = true;
    macvlans = [ "eno0" ];
    privateNetwork = false;
    bindMounts = {
      "/var/lib/caddy/gandi.env" = {
        hostPath = config.age.secrets."gandi.env".path;
        isReadOnly = true;
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
            reverse_proxy {labels.2}.svc.bastille.vtluug.org:80
          '';
          globalConfig = ''    
            acme_dns gandi {$GANDI_AUTH_TOKEN}
          '';
        };
        systemd.services.caddy.serviceConfig.EnvironmentFile = ["/var/lib/caddy/gandi.env"];

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
