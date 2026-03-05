{
  lib,
  lanIface,
  lan,
  wanIface,
  wgIface,
  ...
}:
let
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
    generateInterVlanBlockPairings (
      builtins.filter (e: !builtins.hasAttr "untagged" e.snd) (
        lib.lists.zipLists (builtins.attrNames lan) (builtins.attrValues lan)
      )
    )
  );

  untaggedInterVlanBlock = lib.strings.concatStringsSep "\n" (
    builtins.map
      (e: ''
        iifname "vlan${e.fst}" oifname "${lanIface}" drop comment "Drop vlan${e.fst} to ${lanIface} traffic"
        iifname "${lanIface}" oifname "vlan${e.fst}" drop comment "Drop ${lanIface} to vlan${e.fst} traffic"
      '')
      (
        builtins.filter (e: !builtins.hasAttr "untagged" e.snd) (
          lib.lists.zipLists (builtins.attrNames lan) (builtins.attrValues lan)
        )
      )
  );

  routerAccess = lib.strings.concatStringsSep "\n" (
    builtins.map
      (e: ''iifname { "vlan${e.fst}" } accept comment "Allow vlan${e.fst} to access the router"'')
      (
        builtins.filter (e: e.snd.allowRouterAccess && !builtins.hasAttr "untagged" e.snd) (
          lib.lists.zipLists (builtins.attrNames lan) (builtins.attrValues lan)
        )
      )
  );

  routerForward = lib.strings.concatStringsSep "\n" (
    builtins.map
      (e: ''
        iifname { "vlan${e.fst}" } oifname { "${wanIface}" } accept comment "Allow vlan${e.fst} to WAN"
        iifname { "${wanIface}" } oifname { "vlan${e.fst}" } ct state established, related accept comment "Allow established back to vlan${e.fst}"
      '')
      (
        builtins.filter (e: !builtins.hasAttr "untagged" e.snd) (
          lib.lists.zipLists (builtins.attrNames lan) (builtins.attrValues lan)
        )
      )
  );

  routerIpv6IcmpAccess = lib.strings.concatStringsSep "\n" (
    builtins.map
      (e: ''
        iifname "vlan${e.fst}" ip6 nexthdr icmpv6 icmpv6 type { nd-router-solicit, nd-router-advert, nd-neighbor-solicit, nd-neighbor-advert } counter accept comment "Allow SLAAC and DHCPv6 on vlan${e.fst}"
      '')
      (
        builtins.filter (e: !builtins.hasAttr "untagged" e.snd) (
          lib.lists.zipLists (builtins.attrNames lan) (builtins.attrValues lan)
        )
      )
  );

  routerIpv6NdForward = lib.strings.concatStringsSep "\n" (
    builtins.map
      (e: ''
        iifname "vlan${e.fst}" ip6 nexthdr icmpv6 icmpv6 type { nd-router-solicit, nd-router-advert, nd-neighbor-solicit, nd-neighbor-advert } accept comment "Allow essential ND in FORWARD on vlan${e.fst}"
      '')
      (
        builtins.filter (e: !builtins.hasAttr "untagged" e.snd) (
          lib.lists.zipLists (builtins.attrNames lan) (builtins.attrValues lan)
        )
      )
  );

in
{
  networking.firewall = {
    enable = true;
    allowPing = true;
    trustedInterfaces = [ lanIface ];
  };

  networking.nftables = {
    enable = true;
    ruleset = ''
      table ip filter {
        chain input {
          type filter hook input priority 0; policy drop;

          iifname { "${lanIface}" } accept comment "Allow local network to access the router"
          iifname { "${wgIface}" } accept comment "Allow wireguard network to access the router"

          ${routerAccess}

          iifname "${wanIface}" ct state { established, related } accept comment "Allow established traffic"
          iifname "${wanIface}" icmp type { echo-request, destination-unreachable, time-exceeded } counter accept comment "Allow select ICMP"
          iifname "${wanIface}" tcp dport 2222 accept comment "SSH allow from outside"
          iifname "${wanIface}" tcp dport 22 accept comment "SSH allow from outside"
          iifname "${wanIface}" udp dport 51820 accept comment "Wireguard allow from outside"
          iifname "${wanIface}" counter drop comment "Drop all other unsolicited traffic from wan"

          iif lo accept comment "Allow all loopback traffic"
        }

        chain forward {
          type filter hook forward priority 0; policy drop;

          ${interVlanRoutingBlock}
          ${untaggedInterVlanBlock}

          iifname { "${lanIface}" } oifname { "${wanIface}" } accept comment "Allow trusted LAN to WAN"
          iifname { "${wanIface}" } oifname { "${lanIface}" } ct state established, related accept comment "Allow established back to LANs"

          ${routerForward}

          iifname { "${lanIface}" } oifname { "${wgIface}" } accept comment "Allow LAN to wireguard"
          iifname { "${wgIface}" } oifname { "${lanIface}" } accept comment "Allow wireguard back to LANs"
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

          ${routerAccess}

          iifname "${wanIface}" ct state { established, related } accept comment "Allow established traffic"
          iifname "${wanIface}" icmpv6 type { echo-request, destination-unreachable, time-exceeded } counter accept comment "Allow select ICMP"
          iifname "${wanIface}" tcp dport 2222 accept comment "SSH allow from outside"
          iifname "${wanIface}" tcp dport 22 accept comment "SSH allow from outside"
          iifname "${wanIface}" udp dport 51820 accept comment "Wireguard allow from outside"
          iifname "${wanIface}" counter drop comment "Drop all other unsolicited traffic from WAN"

          iif lo accept comment "Allow all loopback traffic"

          iifname "${lanIface}" ip6 nexthdr icmpv6 icmpv6 type { nd-router-solicit, nd-router-advert, nd-neighbor-solicit, nd-neighbor-advert } counter accept comment "Allow SLAAC and DHCPv6"
          ${routerIpv6IcmpAccess}
        }

        chain forward {
          type filter hook forward priority 0; policy drop;

          ${interVlanRoutingBlock}
          ${untaggedInterVlanBlock}

          iifname { "${lanIface}" } oifname { "${wanIface}" } accept comment "Allow trusted LAN to WAN"
          iifname { "${wanIface}" } oifname { "${lanIface}" } ct state established, related accept comment "Allow established back to LANs"

          ${routerForward}

          iifname { "${lanIface}" } oifname { "${wgIface}" } accept comment "Allow LAN to Tailscale"
          iifname { "${wgIface}" } oifname { "${lanIface}" } accept comment "Allow tailscale back to LANs"

          iifname "${lanIface}" ip6 nexthdr icmpv6 icmpv6 type { nd-router-solicit, nd-router-advert, nd-neighbor-solicit, nd-neighbor-advert } accept comment "Allow essential ND in FORWARD"
          ${routerIpv6NdForward}
        }
      }
    '';
  };
}
