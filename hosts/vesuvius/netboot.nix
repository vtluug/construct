{ config, lib, pkgs, ... }:
let
  dom_ip = "10.98.3.2";
  vlan_router_ip = "10.98.3.1";
  dns_server_ip = "10.98.0.1";
  dhcp_iface = "enp1s0f1";
  client_range = "10.98.3.3,10.98.3.100";


  sub_image = lib.nixosSystem {
    system = "x86_64-linux";

    modules = [
      ../prospit/configuration.nix
    ];
  };

  prospit = sub_image.config.system.build;

  ipxe_config = pkgs.writeText "boot.ipxe" ''
    #!ipxe
    kernel http://${dom_ip}:8080/netboot-kernel/bzImage init=${prospit.toplevel}/init boot.shell_on_fail
    initrd http://${dom_ip}:8080/netboot-initrd/initrd

    boot
  '';

  webroot = pkgs.linkFarm "netboot" [
    { name = "netboot-kernel"; path = prospit.kernel; }
    { name = "netboot-initrd"; path = prospit.netbootRamdisk; }
    { name = "boot.ipxe"; path = ipxe_config; }
  ];

  # fyi this is cause tftpd in dnsmasq chroots and wouldn't follow external symlinks
  #  like the ones in a linkfarm
  tftproot = pkgs.runCommand "tftproot-real" {} ''
    mkdir -p $out
    cp ${ipxe_config} $out/boot.ipxe
    cp ${pkgs.ipxe}/ipxe.efi $out/ipxe.efi
  '';
in
{
  networking.interfaces."${dhcp_iface}".ipv4.addresses = [
    {
      address = dom_ip;
      prefixLength = 24;
    }
  ];

  services.dnsmasq = {
    enable = true;
    settings.domain = "hephaestus.vtluug.org";
    settings.interface = "${dhcp_iface}";
    settings.bind-interfaces = true;
    settings.server = [ "${dns_server_ip}" ];
    settings.enable-tftp = true;
    settings.tftp-root = "${tftproot}";
    settings.dhcp-range = "${client_range},12h";
    settings.dhcp-option = [ "option:router,${vlan_router_ip}" ];
    settings.dhcp-userclass = [ "set:ipxe,iPXE" ];
    settings.dhcp-boot = [
      "tag:!ipxe,ipxe.efi"
      "http://${dom_ip}:8080/boot.ipxe"
    ];
  };

  services.nginx = {
    enable = true;
    virtualHosts."netboot" = {
      listen = [{ port = 8080; addr = "0.0.0.0"; }];
      locations."/".root = "${webroot}";
    };
  };

  networking.firewall = {
    allowedTCPPorts = [ 8080 ];
    allowedUDPPorts = [ 67 69 ];
  };
}
