{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    emacs
    git
    helix
    nano
    neovim
    python3
    rsync
    sl
    tldr
    wget
  ];
}
