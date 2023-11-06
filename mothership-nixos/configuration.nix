{ config, pkgs, lib, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Minimal list of modules to use the EFI system partition and the YubiKey + nouveau
  boot.initrd.kernelModules = [ "vfat" "nls_cp437" "nls_iso8859-1" "usbhid" ];

  nixpkgs.config.allowUnfree = true;

  # Configuration to use your Luks device
  boot.initrd.luks.devices = {
    "encrypted" = {
      device = "/dev/nvme1n1p2";
      preLVM = true; # You may want to set this to false if you need to start a network service first
      yubikey = {
        slot = 2;
        twoFactor = false; # Set to false if you did not set up a user password.
        storage = {
          device = "/dev/nvme1n1p1";
        };
      };
    };
  };

  networking.hostName = "mothership"; # Define your hostname.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp7s0.useDHCP = true;
  networking.interfaces.wlan0.useDHCP = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

  hardware.bluetooth.enable = true;
  hardware.xpadneo.enable = true;
  services.blueman.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware = {
    # video.hidpi.enable = true;
    nvidia = {
      modesetting.enable = true;
      package = config.boot.kernelPackages.nvidiaPackages.beta;
    };
  };

  hardware.openrazer.enable = true;
}

