{ lib, pkgs, ... }:
let
  blades = import ./blade-names.nix;

  assignedBlades = lib.filterAttrs (
    _: blade: blade.frontendIP4 != null
  ) blades;

  macCases = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: blade: ''
      ${lib.escapeShellArg blade.frontendMAC})
        backend_ip=${lib.escapeShellArg blade.backendIP4}
        blade_name=${lib.escapeShellArg name}
        break
        ;;
    '') assignedBlades
  );

  bnx2xFirmware = pkgs.runCommand "bnx2x-firmware" { } ''
    mkdir -p $out/lib/firmware/bnx2x
    cp ${pkgs.linux-firmware}/lib/firmware/bnx2x/bnx2x-e2-7.13.15.0.fw \
      ${pkgs.linux-firmware}/lib/firmware/bnx2x/bnx2x-e2-7.13.21.0.fw \
      $out/lib/firmware/bnx2x/
  '';
in
{
  boot.kernelModules = [ "bonding" ];
  hardware.firmware = [ bnx2xFirmware ];

  systemd.services.blade-backend-network = {
    description = "Configure this blade's static backend address";
    wantedBy = [ "multi-user.target" ];
    before = [ "k3s.service" ];
    after = [ "network-setup.service" ];
    wants = [ "network-setup.service" ];

    path = [
      pkgs.coreutils
      pkgs.iproute2
    ];

    script = ''
      backend_ip=
      blade_name=

      for interface in /sys/class/net/*; do
        [ -f "$interface/address" ] || continue
        frontend_mac=$(cat "$interface/address")
        case "$frontend_mac" in
          ${macCases}
        esac
      done

      if [ -z "$backend_ip" ]; then
        echo "No backend address is assigned to a local frontend MAC" >&2
        exit 1
      fi

      echo "Configuring $blade_name with $backend_ip/24 on bond0"

      for interface in ens6f0 ens6f1; do
        retries=60
        while [ ! -e "/sys/class/net/$interface" ]; do
          if [ "$retries" -eq 0 ]; then
            echo "Timed out waiting for $interface" >&2
            exit 1
          fi
          retries=$((retries - 1))
          sleep 0.5
        done
      done

      if [ ! -e /sys/class/net/bond0 ]; then
        ip link add name bond0 type bond \
          mode 802.3ad \
          miimon 100 \
          lacp_rate fast \
          xmit_hash_policy layer3+4
      fi

      for interface in ens6f0 ens6f1; do
        ip link set "$interface" down
        ip link set "$interface" master bond0
      done

      ip link set bond0 up
      ip address replace "$backend_ip/24" dev bond0
      ip route replace 10.98.3.0/24 dev bond0 src "$backend_ip"

      printf 'node-ip: %s\n' "$backend_ip" > /run/blade-k3s.yaml
    '';

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  systemd.services.k3s = {
    after = [ "blade-backend-network.service" ];
    requires = [ "blade-backend-network.service" ];
    environment.K3S_CONFIG_FILE = "/run/blade-k3s.yaml";
  };
}
