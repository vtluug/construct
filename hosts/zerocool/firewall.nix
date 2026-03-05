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

  generateInterVlanBlockPairings =
    list:
    builtins.concatLists (
      map (
        x:
        map (
          y:
          ''iifname "vlan${x.fst}" oifname "vlan${y.fst}" drop comment "Drop vlan${x.fst} to vlan${y.fst} traffic"''
        ) (builtins.filter (y: x.fst != y.fst) list)
      ) list
    );

  interVlanRoutingBlock = lib.strings.concatStringsSep "\n" (
    generateInterVlanBlockPairings taggedVlans
  );

  untaggedInterVlanBlock = lib.strings.concatStringsSep "\n" (
    builtins.map (e: ''
      iifname "vlan${e.fst}" oifname "${lanIface}" drop comment "Drop vlan${e.fst} to ${lanIface} traffic"
      iifname "${lanIface}" oifname "vlan${e.fst}" drop comment "Drop ${lanIface} to vlan${e.fst} traffic"
    '') taggedVlans
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
    builtins.map
      (e: ''
        iifname { "vlan${e.fst}" } udp dport { 53, 67 } accept comment "Allow vlan${e.fst} DHCP and DNS access the router"
        iifname { "vlan${e.fst}" } tcp dport 53 accept comment "Allow vlan${e.fst} TCP DNS access the router"
      '')
      (
        builtins.filter (
          e:
          !e.snd.allowRouterAccess && (builtins.hasAttr "dhcpv4" e.snd)
        ) taggedVlans
      )
  );

  deniedVlanDhcpv6Access = lib.strings.concatStringsSep "\n" (
    builtins.map
      (e: ''
        iifname { "vlan${e.fst}" } udp dport { 53, 547 } accept comment "Allow vlan${e.fst} DHCP and DNS access the router"
        iifname { "vlan${e.fst}" } tcp dport 53 accept comment "Allow vlan${e.fst} TCP DNS access the router"
      '')
      (
        builtins.filter (
          e:
          !e.snd.allowRouterAccess && (builtins.hasAttr "dhcpv6" e.snd)
        ) taggedVlans
      )
  );


  routerForward = lib.strings.concatStringsSep "\n" (
    builtins.map (e: ''
      iifname { "vlan${e.fst}" } oifname { "${wanIface}" } accept comment "Allow vlan${e.fst} to WAN"
      iifname { "${wanIface}" } oifname { "vlan${e.fst}" } ct state established, related accept comment "Allow established back to vlan${e.fst}"
    '') taggedVlans
  );

  routerIpv6IcmpAccess = lib.strings.concatStringsSep "\n" (
    builtins.map (e: ''
      iifname "vlan${e.fst}" ip6 nexthdr icmpv6 icmpv6 type { nd-router-solicit, nd-router-advert, nd-neighbor-solicit, nd-neighbor-advert } counter accept comment "Allow SLAAC and DHCPv6 on vlan${e.fst}"
    '') taggedVlans
  );

  routerIpv6NdForward = lib.strings.concatStringsSep "\n" (
    builtins.map (e: ''
      iifname "vlan${e.fst}" ip6 nexthdr icmpv6 icmpv6 type { nd-router-solicit, nd-router-advert, nd-neighbor-solicit, nd-neighbor-advert } accept comment "Allow essential ND in FORWARD on vlan${e.fst}"
    '') taggedVlans
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
      iifname { "${wanIface}" } daddr ${daddr} accept comment "Expose ${daddr} to WAN"
    '') wan.exposeIpv4Hosts
  );

  exposedIpv6Hosts = lib.strings.concatStringsSep "\n" (
    builtins.map (daddr: ''
      iifname { "${wanIface}" } daddr ${daddr} accept comment "Expose ${daddr} to WAN"
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

          iifname { "${lanIface}" } accept comment "Allow local network to access the router"
          iifname { "${wgIface}" } accept comment "Allow wireguard network to access the router"

          ${deniedVlanDhcpv4Access}
          ${routerAccess}

          iifname "${wanIface}" ct state { established, related } accept comment "Allow established traffic"
          iifname "${wanIface}" icmp type { echo-request, destination-unreachable, time-exceeded } counter accept comment "Allow select ICMP"

          ${exposedUdpPorts}
          ${exposedTcpPorts}

          iifname "${wanIface}" counter drop comment "Drop all other unsolicited traffic from wan"

          ${routerDenyAccess}

          iif lo accept comment "Allow all loopback traffic"
        }

        chain forward {
          type filter hook forward priority 0; policy drop;

          ${interVlanRoutingBlock}
          ${untaggedInterVlanBlock}

          iifname { "${lanIface}" } oifname { "${wanIface}" } accept comment "Allow trusted LAN to WAN"
          iifname { "${wanIface}" } oifname { "${lanIface}" } ct state established, related accept comment "Allow established back to LANs"
          iifname { "${lanIface}" } oifname { "${wgIface}" } accept comment "Allow LAN to wireguard"
          iifname { "${wgIface}" } oifname { "${lanIface}" } accept comment "Allow wireguard back to LANs"

          ${routerForward}

          ${exposedIpv4Hosts}
        }
      }

      table ip nat {
        chain postrouting {
          type nat hook postrouting priority 100; policy accept;
          oifname "${wanIface}" masquerade comment "NAT IPv4 traffic to WAN"
        }
      }

      table ip6 filter {
        chain input {
          type filter hook input priority 0; policy drop;

          iifname { "${lanIface}" } accept comment "Allow local network to access the router"
          iifname { "${wgIface}" } accept comment "Allow wireguard to access the router"

          ${deniedVlanDhcpv6Access}
          ${routerAccess}

          iifname "${wanIface}" ct state { established, related } accept comment "Allow established traffic"
          iifname "${wanIface}" icmpv6 type { echo-request, destination-unreachable, time-exceeded } counter accept comment "Allow select ICMP"

          ${exposedUdpPorts}
          ${exposedTcpPorts}

          iifname "${wanIface}" counter drop comment "Drop all other unsolicited traffic from WAN"

          iifname "${lanIface}" ip6 nexthdr icmpv6 icmpv6 type { nd-router-solicit, nd-router-advert, nd-neighbor-solicit, nd-neighbor-advert } counter accept comment "Allow SLAAC and DHCPv6"
          ${routerIpv6IcmpAccess}

          ${routerDenyAccess}

          iif lo accept comment "Allow all loopback traffic"
        }

        chain forward {
          type filter hook forward priority 0; policy drop;

          ${interVlanRoutingBlock}
          ${untaggedInterVlanBlock}

          iifname { "${lanIface}" } oifname { "${wanIface}" } accept comment "Allow trusted LAN to WAN"
          iifname { "${wanIface}" } oifname { "${lanIface}" } ct state established, related accept comment "Allow established back to LANs"
          iifname { "${lanIface}" } oifname { "${wgIface}" } accept comment "Allow LAN to wireguard"
          iifname { "${wgIface}" } oifname { "${lanIface}" } accept comment "Allow wireguard back to LANs"

          ${routerForward}

          iifname "${lanIface}" ip6 nexthdr icmpv6 icmpv6 type { nd-router-solicit, nd-router-advert, nd-neighbor-solicit, nd-neighbor-advert } accept comment "Allow essential ND in FORWARD"
          ${routerIpv6NdForward}

          ${exposedIpv6Hosts}
        }
      }
    '';
  };
}
