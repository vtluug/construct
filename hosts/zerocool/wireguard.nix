{ wg_iface }:
{
  #age.secrets."zerocool_wg_private".file = ../../secrets/zerocool_wg_private.age;
  networking.wireguard.interfaces = {
    "${wg_iface}" = {
      ips = [ "10.98.255.2/32" ];
      listenPort = 51820;

      #privateKeyFile = config.age.secrets."zerocool_wg_private".path;
      privateKey = (import ../../secrets/zerocool_wg.nix).private;

      allowedIPsAsRoutes = true;

      peers = [
        { # shellshock
          publicKey = "gEk7+YfwkxM89v+nqlGZTcaxMlhAN5vCCE8U+w+Vy2g=";
          endpoint = "128.173.88.191:51820";
          allowedIPs = [ 
            "10.98.255.1/32" # wg fabric
            "10.98.0.0/21" # whit
          ];
          persistentKeepalive = 25;
        }
      ];
    };
  };
}