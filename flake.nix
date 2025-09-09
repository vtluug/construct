{
  description = "VTLUUG nixos server flakes";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
  }:
  flake-parts.lib.mkFlake {inherit inputs;} {
    systems = [
      "aarch64-darwin"
      "x86_64-linux"
    ];

    flake = {
      nixosConfigurations = {
        blockbuster = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            (import ./hosts/blockbuster/configuration.nix)
          ];
        };
      };
    };

    perSystem = {
      system,
      pkgs,
      ...
    }:
    let pkgs = import nixpkgs { inherit system; }; in
    {
      packages.deploy = pkgs.writeShellScriptBin "deploy" ''
        TARGET_HOST_NAME="$1"
        TARGET_HOST_ADDRESS="$2"

        echo "building $TARGET_HOST_NAME and deploying to $TARGET_HOST_ADDRESS"

        NIX_SSHOPTS="-o ForwardAgent=yes -J acidburn.vtluug.org" \
        ${pkgs.nixos-rebuild}/bin/nixos-rebuild switch \
          --fast --flake ".#$TARGET_HOST_NAME" \
          --use-remote-sudo \
          --target-host "papatux@$TARGET_HOST_ADDRESS" \
          --build-host "papatux@$TARGET_HOST_ADDRESS"
      '';

      packages.ponyfetch = pkgs.writeShellApplication {
        name = "ponyfetch";
        runtimeInputs = [
          pkgs.fastfetch
          pkgs.ponysay
        ];
        text = ''
          if [[ $# -eq 1 ]]; then
            ssh "papatux@$1" nix run nixpkgs#fastfetch -- --pipe false | ponysay -b round -W 120 -f "$1"
          else
            fastfetch --pipe false | ponysay -b round -W 120 -f "$(hostname)"
          fi
        '';
      };
    };
  };
}
