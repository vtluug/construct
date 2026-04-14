{ config, pkgs, ... }:
{
  boot.kernelParams = [ "nvidia-drm.modeset=1" ];
  boot.initrd.kernelModules = [ "nvidia" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.nvidia_x11 ];

  # Needed to enable Nvidia stuff :(
  nixpkgs.config.allowUnfree = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # P100s don't work with the open-source shim
    open = false;
    modesetting.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    nvidiaPersistenced = true;
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Install CUDA and stuff
  nixpkgs.config.cudaSupport = true;
  environment.systemPackages = with pkgs; [
    cudaPackages.cudatoolkit
    nvidia-vaapi-driver
    nvtopPackages.nvidia
    pciutils
  ];
}
