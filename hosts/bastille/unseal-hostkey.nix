{ lib, pkgs, ... }:
let
  blades = import ./blade-names.nix;
  bladeHosts = ../../secrets/blade-hosts;

  secretHosts = lib.attrNames (
    lib.filterAttrs (
      name: type:
        type == "directory"
        && builtins.hasAttr name blades
        && builtins.pathExists (bladeHosts + "/${name}/data")
        && builtins.pathExists (bladeHosts + "/${name}/ssh-key.sealed")
        && builtins.pathExists (bladeHosts + "/${name}/ssh-key.pub")
    ) (builtins.readDir bladeHosts)
  );

  macCases = lib.concatMapStringsSep "\n" (name: ''
    ${lib.escapeShellArg blades.${name}.frontendMAC})
      blade_name=${lib.escapeShellArg name}
      blade_secrets=${bladeHosts + "/${name}"}
      break
      ;;
  '') secretHosts;

  tcsdConfig = pkgs.writeText "blade-tcsd.conf" ''
    system_ps_file = /var/lib/tpm/system.data
  '';

  hostKeyPath = "/run/ssh-host-keys/ssh_host_ed25519_key";
in
{
  age.identityPaths = lib.mkForce [ hostKeyPath ];

  services.openssh = {
    generateHostKeys = false;
    hostKeys = lib.mkForce [
      {
        path = hostKeyPath;
        type = "ed25519";
      }
    ];
  };

  systemd.services.unseal-blade-host-key = {
    description = "Unseal this blade's TPM-bound SSH host key";
    requiredBy = [
      "agenix.service"
      "sshd.service"
    ];
    before = [
      "agenix.service"
      "sshd.service"
    ];

    path = [
      pkgs.coreutils
      pkgs.tpm-tools
      pkgs.trousers
    ];

    script = ''
      blade_name=
      blade_secrets=

      for interface in /sys/class/net/*; do
        [ -f "$interface/address" ] || continue
        frontend_mac=$(cat "$interface/address")
        case "$frontend_mac" in
          ${macCases}
        esac
      done

      if [ -z "$blade_secrets" ]; then
        echo "No sealed host key matches a local frontend MAC" >&2
        exit 1
      fi

      echo "Unsealing the SSH host key for $blade_name"

      install -d -m 0700 /var/lib/tpm /run/ssh-host-keys
      install -m 0600 "$blade_secrets/data" /var/lib/tpm/system.data

      tcsd -f -c ${tcsdConfig} &
      tcsd_pid=$!
      trap 'kill "$tcsd_pid" 2>/dev/null || true' EXIT

      # tcsd creates its socket asynchronously. Retry the unseal briefly rather
      # than racing it during early boot.
      unsealed_key=$(mktemp /run/ssh-host-keys/.host-key.XXXXXX)
      rm "$unsealed_key"
      retries=50
      until tpm_unsealdata -z \
        -i "$blade_secrets/ssh-key.sealed" \
        -o "$unsealed_key"; do
        rm -f "$unsealed_key"
        if [ "$retries" -eq 0 ]; then
          echo "Timed out unsealing $blade_name's SSH host key" >&2
          exit 1
        fi
        retries=$((retries - 1))
        sleep 0.1
      done

      chmod 0600 "$unsealed_key"
      mv "$unsealed_key" ${lib.escapeShellArg hostKeyPath}
    '';

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      UMask = "0077";
    };
  };
}
