{ config, pkgs, ... }:
let
  dom_ip = "10.98.2.1";
  dhcp_iface = "enp1s0f1";
  client_range = "10.98.2.2,10.98.2.100";

  sub_image = pkgs.nixos {
    imports = [ "${pkgs.path}/nixos/modules/installer/netboot/netboot-minimal.nix" ];

    system.stateVersion = "25.05";
    services.openssh = {
      enable = true;
      settings.PasswordAuthentication = true;
      settings.KbdInteractiveAuthentication = false;
    };

    users.users.papatux = {
      isNormalUser = true;
      description = "papatux";
      extraGroups = [ "networkmanager" "wheel" ];
      hashedPassword = "$6$6GnvJWpo8oOWM1tb$GhuldW5iIdS6OuRyq5u1hSSu0VotQCLac7emA.Kui2hWLozR7EIO4Su6PCo5hTRG8iWnAOlGemQVyejIA9l4j/";
      openssh.authorizedKeys.keys = import ../../papatux-keys.nix;
    };
  };
  
  ipxe_config = pkgs.writeText "boot.ipxe" ''
    #!ipxe
    kernel http://${dom_ip}:8080/netboot-nixtest/kernel init=/init boot.shell_on_fail
    initrd http://${dom_ip}:8080/netboot-nixtest/initrd

    boot
  '';

  webroot = pkgs.linkFarm "netboot" [
    { name = "netboot-nixtest"; path = sub_image.config.system.build.toplevel; }
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
    settings.enable-tftp = true;
    settings.tftp-root = "${tftproot}";
    settings.dhcp-range = "${client_range},12h";
    settings.dhcp-option = [ "option:router,${dom_ip}" ];
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