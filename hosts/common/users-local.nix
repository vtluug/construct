{ config, pkgs, ... }:
{
  security.sudo.wheelNeedsPassword = false;

  users.users = {
    root = {
      hashedPassword = "$6$XdWPRN.x2YzdWF8c$WcXgkl6Hndm/xX6Fd7Wf6iMe9RG9j3fwan49/GumSfxCaydcgGgUD4I63QLO8hNiTp7VmrkhDJHyZ8tgsD4nE0";
    };
    papatux = {
      isNormalUser = true;
      description = "papatux";
      extraGroups = [ "networkmanager" "wheel" ];
      openssh.authorizedKeys.keys = import ../../papatux-keys.nix;
      hashedPassword = "$6$Aph/0comvK6RL3WN$7g6nKH2l5nBTs5laugQlOE9iIsxdP9pUmsnXuoGnUBiHF1HPqb5A4RN/cpEhc5NG94YXv114GNrT8KGbYGLTH.";
    };
  };
}
