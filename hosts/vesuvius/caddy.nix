{
  config,
  pkgs,
  lib,
  ...
}:
{
  containers.caddy-proxy = {
    autoStart = true;
    ephemeral = true;
    macvlans = [ "eno0" ];
    privateNetwork = false;
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
          virtualHosts."ephemeral.vtluug.org".extraConfig = ''
            reverse_proxy http://ephemeral-chat.svc.bastille.vtluug.org:80
          '';
        };

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
