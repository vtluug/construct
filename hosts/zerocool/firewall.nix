{
  lib,
  lan_iface,
  lan,
  wan_iface,
  wg_iface,
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

  intervlan_forward_block = lib.strings.concatStringsSep "\n" (
    generateInterVlanBlockPairings (
      builtins.filter (e: !builtins.hasAttr "untagged" e.snd) (
        lib.lists.zipLists (builtins.attrNames lan) (builtins.attrValues lan)
      )
    )
  );

  untagged_intervlan_block = lib.strings.concatStringsSep "\n" (
    builtins.map
      (e: ''
        iifname "vlan${e.fst}" oifname "${lan_iface}" drop comment "Drop vlan${e.fst} to ${lan_iface} traffic"
        iifname "${lan_iface}" oifname "vlan${e.fst}" drop comment "Drop ${lan_iface} to vlan${e.fst} traffic"
      '')
      (
        builtins.filter (e: !builtins.hasAttr "untagged" e.snd) (
          lib.lists.zipLists (builtins.attrNames lan) (builtins.attrValues lan)
        )
      )
  );

  router_access = lib.strings.concatStringsSep "\n" (
    builtins.map
      (e: ''iifname { "vlan${e.fst}" } accept comment "Allow vlan${e.fst} to access the router"'')
      (
        builtins.filter (e: e.snd.allow_router_access && !builtins.hasAttr "untagged" e.snd) (
          lib.lists.zipLists (builtins.attrNames lan) (builtins.attrValues lan)
        )
      )
  );

  router_forward = lib.strings.concatStringsSep "\n" (
    builtins.map
      (e: ''
        iifname { "vlan${e.fst}" } oifname { "${wan_iface}" } accept comment "Allow vlan${e.fst} to WAN"
        iifname { "${wan_iface}" } oifname { "vlan${e.fst}" } ct state established, related accept comment "Allow established back to vlan${e.fst}"
      '')
      (
        builtins.filter (e: !builtins.hasAttr "untagged" e.snd) (
          lib.lists.zipLists (builtins.attrNames lan) (builtins.attrValues lan)
        )
      )
  );

  router_ipv6_icmp_access = lib.strings.concatStringsSep "\n" (
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

  router_ipv6_nd_forward = lib.strings.concatStringsSep "\n" (
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
    trustedInterfaces = [ lan_iface ];
  };

  networking.nftables = {
    enable = true;
    ruleset = ''
      table ip filter {
        chain input {
          type filter hook input priority 0; policy drop;

          iifname { "${lan_iface}" } accept comment "Allow local network to access the router"
          iifname { "${wg_iface}" } accept comment "Allow wireguard network to access the router"

          ${router_access}

          iifname "${wan_iface}" ct state { established, related } accept comment "Allow established traffic"
          iifname "${wan_iface}" icmp type { echo-request, destination-unreachable, time-exceeded } counter accept comment "Allow select ICMP"
          iifname "${wan_iface}" tcp dport 2222 accept comment "SSH allow from outside"
          iifname "${wan_iface}" tcp dport 22 accept comment "SSH allow from outside"
          iifname "${wan_iface}" udp dport 51820 accept comment "Wireguard allow from outside"
          iifname "${wan_iface}" counter drop comment "Drop all other unsolicited traffic from wan"

          iif lo accept comment "Allow all loopback traffic"
        }

        chain forward {
          type filter hook forward priority 0; policy drop;

          ${intervlan_forward_block}
          ${untagged_intervlan_block}

          iifname { "${lan_iface}" } oifname { "${wan_iface}" } accept comment "Allow trusted LAN to WAN"
          iifname { "${wan_iface}" } oifname { "${lan_iface}" } ct state established, related accept comment "Allow established back to LANs"

          ${router_forward}

          iifname { "${lan_iface}" } oifname { "${wg_iface}" } accept comment "Allow LAN to wireguard"
          iifname { "${wg_iface}" } oifname { "${lan_iface}" } accept comment "Allow wireguard back to LANs"
        }
      }

      table ip nat {
        chain postrouting {
          type nat hook postrouting priority 100; policy accept;
          oifname "${wan_iface}" masquerade comment "NAT IPv4 traffic to WAN"
        }
      }

      table ip6 filter {
        chain input {
          type filter hook input priority 0; policy drop;

          iifname { "${lan_iface}" } accept comment "Allow local network to access the router"
          iifname { "${wg_iface}" } accept comment "Allow wireguard to access the router"

          ${router_access}

          iifname "${wan_iface}" ct state { established, related } accept comment "Allow established traffic"
          iifname "${wan_iface}" icmpv6 type { echo-request, destination-unreachable, time-exceeded } counter accept comment "Allow select ICMP"
          iifname "${wan_iface}" tcp dport 2222 accept comment "SSH allow from outside"
          iifname "${wan_iface}" tcp dport 22 accept comment "SSH allow from outside"
          iifname "${wan_iface}" udp dport 51820 accept comment "Wireguard allow from outside"
          iifname "${wan_iface}" counter drop comment "Drop all other unsolicited traffic from WAN"

          iif lo accept comment "Allow all loopback traffic"

          iifname "${lan_iface}" ip6 nexthdr icmpv6 icmpv6 type { nd-router-solicit, nd-router-advert, nd-neighbor-solicit, nd-neighbor-advert } counter accept comment "Allow SLAAC and DHCPv6"
          ${router_ipv6_icmp_access}
        }

        chain forward {
          type filter hook forward priority 0; policy drop;

          ${intervlan_forward_block}
          ${untagged_intervlan_block}

          iifname { "${lan_iface}" } oifname { "${wan_iface}" } accept comment "Allow trusted LAN to WAN"
          iifname { "${wan_iface}" } oifname { "${lan_iface}" } ct state established, related accept comment "Allow established back to LANs"

          ${router_forward}

          iifname { "${lan_iface}" } oifname { "${wg_iface}" } accept comment "Allow LAN to Tailscale"
          iifname { "${wg_iface}" } oifname { "${lan_iface}" } accept comment "Allow tailscale back to LANs"

          iifname "${lan_iface}" ip6 nexthdr icmpv6 icmpv6 type { nd-router-solicit, nd-router-advert, nd-neighbor-solicit, nd-neighbor-advert } accept comment "Allow essential ND in FORWARD"
          ${router_ipv6_nd_forward}
        }
      }
    '';
  };
}
