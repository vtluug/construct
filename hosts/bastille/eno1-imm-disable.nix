{ pkgs, lib, ... }:
let
  eno1-imm-disable = pkgs.writeShellApplication {
    name = "eno1-imm-disable";

    runtimeInputs = [
      pkgs.iproute2
    ];

    text = ''
      if grep "Lenovo NeXtScale nx360 M5" /sys/devices/virtual/dmi/id/product_name; then
        ip link set down eno1
      fi
    '';
  };
in {
  systemd.services."eno1-imm-disable" = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    unitConfig = {
      Description = "Disable eno1 on Lenovo NeXtScale nodes to avoid issues with using the imm interface";
    };

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${lib.getExe eno1-imm-disable}";
    };
  };
}
