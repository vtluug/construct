{ config, wg_iface }:
{
  age.secrets."wg.priv".file = ../../secrets/zerocool/wg.priv.age;
  networking.wireguard.interfaces = {
    "${wg_iface}" = {
      ips = [ "10.98.255.2/32" ];
      listenPort = 51820;

      privateKeyFile = config.age.secrets."wg.priv".path;

      allowedIPsAsRoutes = true;

      peers = [
        { # shellshock
          publicKey = "gEk7+YfwkxM89v+nqlGZTcaxMlhAN5vCCE8U+w+Vy2g=";
          endpoint = "128.173.88.191:51820";
          allowedIPs = [ 
            "10.98.255.1/32" # wg fabric
            "10.98.0.0/22" # whit
          ];
          persistentKeepalive = 25;
        }
      ];
    };
  };
  networking.firewall.allowedUDPPorts = [ 51820 ];
}
