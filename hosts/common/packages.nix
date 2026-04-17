{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    btop
    emacs
    git
    helix
    htop
    nano
    neovim
    python3
    rsync
    sl
    tldr
    wget
  ];
}
