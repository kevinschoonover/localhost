# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ inputs, config, pkgs, ... }:

{
  imports =
    [
      # https://github.com/NixOS/nixos-hardware
      inputs.nixos-hardware.dell-xps-13-9300
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  networking.hostName = "honeypot"; # Define your hostname.

  boot.initrd = {
    kernelModules = [ "dm-snapshot" "vfat" "nls_cp437" "nls_iso8859-1" "usbhid" ];

    luks = {
      yubikeySupport = true;
      devices."encrypted" = {
        device = "/dev/nvme0n1p3";

        yubikey = {
          slot = 2;
          twoFactor = false;
          gracePeriod = 30;
          keyLength = 64;
          saltLength = 16;

          storage = {
            device = "/dev/nvme0n1p2";
            fsType = "vfat";
            path = "/crypt-storage/default";
          };
        };
      };
    };
  };


  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  # networking.interfaces.enp57s0u1u3.useDHCP = true;
  networking.interfaces.wlan0.useDHCP = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?
}

