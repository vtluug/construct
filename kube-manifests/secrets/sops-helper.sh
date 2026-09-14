#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"


usage() {
    echo "Usage: $0 <encrypt|decrypt> <name>"
    echo ""
    echo "  encrypt <name>  Encrypt <name>.yaml -> <name>.enc.yaml"
    echo "  decrypt <name>  Decrypt <name>.enc.yaml -> <name>.yaml"
    echo ""
    echo "Example: $0 encrypt wiki"
    exit 1
}

[[ $# -eq 2 ]] || usage

ACTION="$1"
NAME="$2"

case "$ACTION" in
    encrypt)
        [[ -f "${NAME}.yaml" ]] || { echo "Error: ${NAME}.yaml not found"; exit 1; }
        sops --encrypt "${NAME}.yaml" > "${NAME}.enc.yaml"
        echo "Encrypted ${NAME}.yaml -> ${NAME}.enc.yaml"
        ;;
    decrypt)
        [[ -f "${NAME}.enc.yaml" ]] || { echo "Error: ${NAME}.enc.yaml not found"; exit 1; }
        (umask 077 && sops --decrypt "${NAME}.enc.yaml" > "${NAME}.yaml")
        echo "Decrypted ${NAME}.enc.yaml -> ${NAME}.yaml"
        ;;
    *)
        usage
        ;;
esac
