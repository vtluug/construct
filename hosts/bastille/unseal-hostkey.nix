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

  unsealHostKey = ''
    export PATH=${lib.makeBinPath [
      pkgs.coreutils
      pkgs.tpm-tools
      pkgs.trousers
    ]}

    if [ -s ${lib.escapeShellArg hostKeyPath} ]; then
      exit 0
    fi

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

  system.activationScripts = {
    agenixInstall.text = lib.mkForce "";
    agenixChown.text = lib.mkForce "";
  };

  systemd.services.unseal-blade-host-key = {
    description = "Unseal this blade's TPM-bound SSH host key";
    requiredBy = [
      "install-blade-secrets.service"
      "sshd.service"
    ];
    before = [
      "install-blade-secrets.service"
      "sshd.service"
    ];

    path = [
      pkgs.coreutils
      pkgs.tpm-tools
      pkgs.trousers
    ];

    script = unsealHostKey;

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      UMask = "0077";
    };
  };

  systemd.services.install-blade-secrets = {
    description = "Install agenix secrets using the TPM-unsealed host identity";
    requiredBy = [ "k3s.service" ];
    requires = [ "unseal-blade-host-key.service" ];
    after = [ "unseal-blade-host-key.service" ];
    before = [ "k3s.service" ];

    script = ''
      install -d -m 0751 /run/agenix
      join_token_tmp=$(mktemp /run/agenix/.k3s-join-token.XXXXXX)
      node_password_tmp=$(mktemp /run/.k3s-node-password.XXXXXX)
      trap 'rm -f "$join_token_tmp" "$node_password_tmp"' EXIT
      ${pkgs.age}/bin/age --decrypt \
        -i ${lib.escapeShellArg hostKeyPath} \
        -o "$join_token_tmp" \
        ${../../secrets/k3s-join-token.age}
      chmod 0400 "$join_token_tmp"
      mv "$join_token_tmp" /run/agenix/k3s-join-token

      blade_secrets=
      for interface in /sys/class/net/*; do
        [ -f "$interface/address" ] || continue
        frontend_mac=$(cat "$interface/address")
        case "$frontend_mac" in
          ${macCases}
        esac
      done

      if [ -z "$blade_secrets" ] || [ ! -f "$blade_secrets/k3s-node-password.age" ]; then
        echo "No k3s node-password secret matches a local frontend MAC" >&2
        exit 1
      fi

      ${pkgs.age}/bin/age --decrypt \
        -i ${lib.escapeShellArg hostKeyPath} \
        -o "$node_password_tmp" \
        "$blade_secrets/k3s-node-password.age"
      install -d -m 0700 /etc/rancher/node
      install -m 0600 "$node_password_tmp" /etc/rancher/node/password
    '';

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      UMask = "0077";
    };
  };
}
