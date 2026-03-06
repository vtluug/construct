{
  lib,
  lanIface,
  lan,
  wanIface,
  wan,
  wgIface,
  ...
}:
let
  taggedVlans = (
    builtins.filter (e: !builtins.hasAttr "untagged" e.snd) (
      lib.lists.zipLists (builtins.attrNames lan) (builtins.attrValues lan)
    )
  );

  routerAccess = lib.strings.concatStringsSep "\n" (
    builtins.map (
      e: ''iifname { "vlan${e.fst}" } accept comment "Allow vlan${e.fst} to access the router"''
    ) (builtins.filter (e: e.snd.allowRouterAccess) taggedVlans)
  );

  routerDenyAccess = lib.strings.concatStringsSep "\n" (
    builtins.map (
      e: ''iifname { "vlan${e.fst}" } drop comment "Deny vlan${e.fst} to access the router"''
    ) (builtins.filter (e: !e.snd.allowRouterAccess) taggedVlans)
  );

  deniedVlanDhcpv4Access = lib.strings.concatStringsSep "\n" (
    builtins.map (e: ''
      iifname { "vlan${e.fst}" } udp dport { 53, 67 } accept comment "Allow vlan${e.fst} DHCP and DNS access the router"
      iifname { "vlan${e.fst}" } tcp dport 53 accept comment "Allow vlan${e.fst} TCP DNS access the router"
    '') (builtins.filter (e: !e.snd.allowRouterAccess && (builtins.hasAttr "dhcpv4" e.snd)) taggedVlans)
  );

  deniedVlanDhcpv6Access = lib.strings.concatStringsSep "\n" (
    builtins.map (e: ''
      iifname { "vlan${e.fst}" } udp dport { 53, 547 } accept comment "Allow vlan${e.fst} DHCP and DNS access the router"
      iifname { "vlan${e.fst}" } tcp dport 53 accept comment "Allow vlan${e.fst} TCP DNS access the router"
    '') (builtins.filter (e: !e.snd.allowRouterAccess && (builtins.hasAttr "dhcpv6" e.snd)) taggedVlans)
  );

  exposedUdpPorts = lib.strings.concatStringsSep "\n" (
    builtins.map (port: ''
      iifname { "${wanIface}" } udp dport ${toString port} accept comment "Allow UDP port ${toString port} from WAN"
    '') wan.udpPorts
  );

  exposedTcpPorts = lib.strings.concatStringsSep "\n" (
    builtins.map (port: ''
      iifname { "${wanIface}" } tcp dport ${toString port} accept comment "Allow TCP port ${toString port} from WAN"
    '') wan.tcpPorts
  );

  exposedIpv4Hosts = lib.strings.concatStringsSep "\n" (
    builtins.map (daddr: ''
      iifname { "${wanIface}" } ip daddr ${daddr} accept comment "Expose ${daddr} to WAN"
      oifname { "${wanIface}" } ip saddr ${daddr} accept comment "Expose ${daddr} to WAN"

    '') wan.exposeIpv4Hosts
  );

  exposedIpv4HostsNatDisable = lib.strings.concatStringsSep "," (
    builtins.map (toString) wan.exposeIpv4Hosts
  );

  exposedIpv6Hosts = lib.strings.concatStringsSep "\n" (
    builtins.map (daddr: ''
      iifname { "${wanIface}" } ip6 daddr ${daddr} accept comment "Expose ${daddr} to WAN"
      oifname { "${wanIface}" } ip6 saddr ${daddr} accept comment "Expose ${daddr} to WAN"
    '') wan.exposeIpv6Hosts
  );
in
{
  networking.firewall.enable = true;

  networking.nftables = {
    enable = true;
    ruleset = ''
      table ip filter {
        chain input {
          type filter hook input priority 0; policy drop;

          ct state { established, related } accept comment "Allow all established traffic"
          iifname { "${lanIface}" } accept comment "Allow local network to access the router"
          iifname { "${wgIface}" } accept comment "Allow wireguard to access the router"

          ${routerAccess}
          ${deniedVlanDhcpv4Access}

          iifname "${wanIface}" icmp type { echo-request, destination-unreachable, time-exceeded } counter accept comment "Allow select ICMP"

          ${exposedUdpPorts}
          ${exposedTcpPorts}

          ${routerDenyAccess}
          iifname "${wanIface}" counter drop comment "Drop all other unsolicited traffic from wan"

          iif lo accept comment "Allow all loopback traffic"
        }

        chain forward {
          type filter hook forward priority 0; policy drop;

          ct state { established, related } accept comment "Allow all established traffic"
          iifname { "${lanIface}", "vlan*" } oifname { "${wanIface}" } accept comment "Allow all traffic going out"

          iifname { "${lanIface}" } oifname { "${wgIface}" } accept comment "Allow LAN to wireguard"
          iifname { "${wgIface}" } oifname { "${lanIface}" } accept comment "Allow wireguard back to LANs"

          iifname "vlan*" oifname "vlan*" drop comment "Drop inter-VLAN traffic"
          iifname "${lanIface}*" oifname "vlan*" drop comment "Drop LAN to VLAN traffic"
          iifname "vlan*" oifname "${lanIface}*" drop comment "Drop VLAN to LAN traffic"

          ${exposedIpv4Hosts}
        }
      }

      table ip nat {
        chain postrouting {
          type nat hook postrouting priority 100; policy accept;
          oifname "${wanIface}" ip saddr != { ${exposedIpv4HostsNatDisable} } masquerade comment "NAT IPv4 traffic to WAN"
        }
      }

      table ip6 filter {
        chain input {
          type filter hook input priority 0; policy drop;

          ct state { established, related } accept comment "Allow all established traffic"
          iifname { "${lanIface}" } accept comment "Allow local network to access the router"
          iifname { "${wgIface}" } accept comment "Allow wireguard to access the router"
          ${routerAccess}
          ${deniedVlanDhcpv6Access}

          iifname { "${wanIface}", "${lanIface}", "vlan*" } icmpv6 type { 
            destination-unreachable, packet-too-big, time-exceeded, 
            parameter-problem, echo-request, echo-reply,
            nd-router-advert, nd-neighbor-solicit, nd-neighbor-advert 
          } accept comment "Allow essential ICMPv6"

          ${exposedUdpPorts}
          ${exposedTcpPorts}

          ${routerDenyAccess}
          iifname "${wanIface}" counter drop comment "Drop all other unsolicited traffic from WAN"

          iif lo accept comment "Allow all loopback traffic"
        }

        chain output {
          type filter hook output priority 0; policy accept;
        }

        chain forward {
          type filter hook forward priority 0; policy drop;

          ct state { established, related } accept comment "Allow all established traffic"
          iifname { "${lanIface}", "vlan*" } oifname { "${wanIface}" } accept comment "Allow all traffic going out"

          iifname { "${lanIface}" } oifname { "${wgIface}" } accept comment "Allow LAN to wireguard"
          iifname { "${wgIface}" } oifname { "${lanIface}" } accept comment "Allow wireguard back to LANs"

          iifname "vlan*" oifname "vlan*" drop comment "Drop inter-VLAN traffic"
          iifname "${lanIface}*" oifname "vlan*" drop comment "Drop LAN to VLAN traffic"
          iifname "vlan*" oifname "${lanIface}*" drop comment "Drop VLAN to LAN traffic"

          ${exposedIpv6Hosts}
        }
      }
    '';
  };
}
