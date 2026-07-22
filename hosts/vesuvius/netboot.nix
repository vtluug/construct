{
  config,
  lib,
  pkgs,
  ...
}:
let
  dom_ip = "10.98.3.2";
  vlan_router_ip = "10.98.3.1";
  dns_server_ip = "10.98.0.1";
  dhcp_iface = "enp1s0f1";
  client_range = "10.98.3.3,10.98.3.100";

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
  networking.interfaces."${dhcp_iface}".ipv4.addresses = [
    {
      address = dom_ip;
      prefixLength = 24;
    }
  ];

  services.dnsmasq = {
    enable = true;
    settings = {
      domain = "bastille.vtluug.org";
      domain-needed = true;
      interface = "${dhcp_iface}";
      bind-interfaces = true;
      server = [
        "198.82.247.98"
        "198.82.247.66"
        "198.82.247.34"
        "2001:468:c80:6101:0:100:0:62"
        "2001:468:c80:4101:0:100:0:42"
        "2001:468:c80:2101:0:100:0:22"
        "/whit.vtluug.org/10.98.0.1"
      ];
      enable-tftp = true;
      tftp-root = "${tftproot}";
      dhcp-range = "${client_range},12h";
      dhcp-option = [ "option:router,${vlan_router_ip}" ];
      dhcp-userclass = [ "set:ipxe,iPXE" ];
      dhcp-boot = [
        "tag:!ipxe,ipxe.efi"
        "http://${dom_ip}:8080/boot.ipxe"
      ];
      # Set hostnames via DHCP
      dhcp-host = builtins.map (host: "${host.fst},${host.snd}") (
        lib.lists.filter (host: !lib.strings.hasInfix "unassigned" host.fst) (
          lib.lists.zipLists (builtins.attrNames netboot-hostnames) (builtins.attrValues netboot-hostnames)
        )
      );
      address = [
        "/bastille.vtluug.org/::" # Filter IPv6 so it doesn't just hang forever when resolving every request to local domain
        "/vesuvius.bastille.vtluug.org/${dom_ip}"
        "/svc.bastille.vtluug.org/${dom_ip}"
      ];
      local = [
        "/svc.bastille.vtluug.org/"
      ];
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
