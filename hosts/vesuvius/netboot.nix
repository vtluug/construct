{
  config,
  lib,
  pkgs,
  ...
}:
let
  dom_ip = "10.98.0.23";
  tftp_iface = "eno0";

  netboot-hostnames = import ../bastille/blade-names.nix;

  sub_image = lib.nixosSystem {
    system = "x86_64-linux";

    modules = [
      ../bastille/blade.nix
    ];
  };

  blade = sub_image.config.system.build;

  ipxe_config = pkgs.writeText "boot.ipxe" ''
    #!ipxe
    kernel http://${dom_ip}:8080/netboot-kernel/bzImage init=${blade.toplevel}/init boot.shell_on_fail
    initrd http://${dom_ip}:8080/netboot-initrd/initrd

    boot
  '';

  webroot = pkgs.linkFarm "netboot" [
    {
      name = "netboot-kernel";
      path = blade.kernel;
    }
    {
      name = "netboot-initrd";
      path = blade.netbootRamdisk;
    }
    {
      name = "boot.ipxe";
      path = ipxe_config;
    }
  ];

  # fyi this is cause tftpd in dnsmasq chroots and wouldn't follow external symlinks
  #  like the ones in a linkfarm
  tftproot = pkgs.runCommand "tftproot-real" { } ''
    mkdir -p $out
    cp ${ipxe_config} $out/boot.ipxe
    cp ${pkgs.ipxe}/ipxe.efi $out/ipxe.efi
  '';
in
{
  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = false;
    settings = {
      port = 0; #Disable DNS
      interface = "${tftp_iface}";
      enable-tftp = true;
      tftp-root = "${tftproot}";
    };
  };

  services.nginx = {
    enable = true;
    virtualHosts."netboot" = {
      listen = [
        {
          port = 8080;
          addr = "0.0.0.0";
        }
      ];
      locations."/".root = "${webroot}";
    };
  };

  networking.firewall = {
    allowedTCPPorts = [
      6443
      8080
      10250
    ];
    allowedUDPPorts = [
      53
      67
      69
      8472
    ];
  };
}
