{ pkgs, lib, ... }:
let
  names = import ./blade-names.nix;

  bash-sets = lib.mapAttrsToList (mac: name: "names['${mac}']='${name}'") names;

  auto-hostname = pkgs.writeShellApplication {
    name = "auto-hostname";

    runtimeInputs = [
      pkgs.hostname
    ];

    text = ''
      if [[ -e "/sys/class/net/eno2/address" ]]; then
        mac_file="/sys/class/net/eno2/address"
      else
        mac_file=/sys/class/net/enp0s25/address
      fi

      mac=$(cat $mac_file | tr -d '\r\n ')

      declare -A names
      ${lib.concatLines bash-sets}

      if [[ -v names[$mac] ]]; then
        name=''${names[$mac]}
      else
        name="node-(echo $mac | tr ':' '-')"
      fi

      echo "mac:  '$mac'"
      echo "name: '$name'"

      hostname "$name"
      echo "hostname set to '$(hostname)'"
    '';
  };
in {
  networking.hostName = "";

  systemd.services."auto-hostname" = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    unitConfig = {
      Description = "Automatically set the hostname ";
    };

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${lib.getExe auto-hostname}";
    };
  };
}
