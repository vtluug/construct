{
  config,
  pkgs,
  lib,
  ...
}:
let
  gandi-key-path = "/secrets/gandi.env";
  cluster-router-ip = "10.98.0.192";
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
      "/files" = {
        hostPath = "/nfs/cistern/files";
        isReadOnly = true;
      };
      "/users" = {
        hostPath = "/nfs/cistern/home";
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
          ipv4.routes = [
            {
              address = "10.98.3.0";
              prefixLength = 24;
              via = cluster-router-ip;
              # The route is installed before DHCP adds the private address.
              options.onlink = "";
            }
          ];
        };

        # use vesuvius for dns
        networking.useHostResolvConf = false;
        networking.nameservers = [ "10.98.3.2" ];
        networking.dhcpcd.extraConfig = ''
          nooption domain_name_servers
        '';

        services.caddy = {
          enable = true;
          virtualHosts."wiki.vtluug.org".extraConfig = ''
            tls {
              dns gandi {env.GANDI_AUTH_TOKEN}
            }
            # wiki.vtluug.org redirects to vtluug.org/wiki
            @wikipath path_regexp wikipath ^/(wiki|w)/(.*)$
            redir @wikipath https://vtluug.org/{re.wikipath.1}/{re.wikipath.2} permanent
            redir * https://vtluug.org/wiki/Main_page permanent
          '';
          virtualHosts."gobblerpedia.org".extraConfig = ''
            handle / {
              redir * /wiki/Main_page permanent
            }

            handle /w/* {
              reverse_proxy https://svc.bastille.vtluug.org:443 {
                transport http {
                  tls_insecure_skip_verify
                }
              }
            }
            handle /w {
              reverse_proxy https://svc.bastille.vtluug.org:443 {
                transport http {
                  tls_insecure_skip_verify
                }
              }
            }

            handle_path /wiki/* {
              rewrite * /w/index.php{uri}
              reverse_proxy https://svc.bastille.vtluug.org:443 {
                transport http {
                  tls_insecure_skip_verify
                }
              }
            }
            handle /wiki {
              rewrite * /w/index.php
              reverse_proxy https://svc.bastille.vtluug.org:443 {
                transport http {
                  tls_insecure_skip_verify
                }
              }
            }

            respond /w/cache/* 403
          '';
          virtualHosts."*.vtluug.org".extraConfig = ''
            tls {
              dns gandi {env.GANDI_AUTH_TOKEN}
            }
            reverse_proxy https://svc.bastille.vtluug.org:443 {
              transport http {
                tls_insecure_skip_verify
              }
            }
          '';
          virtualHosts."vtluug.org".extraConfig = ''
            tls {
              dns gandi {env.GANDI_AUTH_TOKEN}
            }
            # Static files (including user homedirs) {{{

            # We got a C&D
            handle_path /files/2013/hamexam/* {
              file_server browse
              root * /files/2013/hamexam
              @denied not remote_ip 127.0.0.1 ::1 10.0.0.0/8 198.82.0.0/16 128.173.0.0/16 2607:b400::/32 2001:468:c80::/48
              respond @denied 403
            }

            redir /files /files/ 308
            handle_path /files/* {
              file_server browse
              root * /files
            }

            @usertilde path_regexp usertilde ^/users/~(.+?)(/.*)?$
            redir @usertilde /~{re.usertilde.1}{re.usertilde.2} permanent

            @tildedir path_regexp tildedir ^/~([^/]+)$
            redir @tildedir /~{re.tildedir.1}/ 308

            @userdir path_regexp userdir ^/~([^/]+)(/.*)?$
            handle @userdir {
              root * /users/{re.userdir.1}/public_html
              rewrite * {re.userdir.2}
              file_server browse
            }
            # }}}

            # LUUG wiki stuff (slightly different vs gobblerpedia) {{{
            # Proxy to internal instance
            handle /w/* {
              reverse_proxy https://svc.bastille.vtluug.org:443 {
                transport http {
                  tls_insecure_skip_verify
                }
              }
            }

            # Displayed path is /wiki, but actual path is /w
            # See $wgScriptPath & $wgArticle path in MW config
            handle_path /wiki/* {
              rewrite * /w/index.php{uri}
              reverse_proxy https://svc.bastille.vtluug.org:443 {
                transport http {
                  tls_insecure_skip_verify
                }
              }
            }
            handle /wiki {
              rewrite * /w/index.php
              reverse_proxy https://svc.bastille.vtluug.org:443 {
                transport http {
                  tls_insecure_skip_verify
                }
              }
            }

            # Deny access to mediawiki cache (shouldn't be enabled anyways)
            respond /w/cache/* 403
            # }}}

            # Main site
            handle {
              reverse_proxy https://svc.bastille.vtluug.org:443 {
                transport http {
                  tls_insecure_skip_verify
                }
              }
            }
          '';
          package = pkgs.caddy.withPlugins {
            plugins = [ "github.com/caddy-dns/gandi@v1.1.0" ];
            hash = "sha256-5mjD0CY7f5+sRtV1rXysj8PvId2gQaWiXlIaTg2Lv8A=";
          };
          globalConfig = ''
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
