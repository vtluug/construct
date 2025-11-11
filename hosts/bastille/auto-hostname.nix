{ pkgs, lib, ... }:
let
  # TODO: make this like a python script with a list of interfaces in order of preference
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

      mac=$(cat $mac_file | tr -d '\r\n ' | tr ':' '-')

      hostname "blade-$mac"
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
