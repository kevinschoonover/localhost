{ config, pkgs, lib, ... }:

let
  unstable = import <nixos-unstable> { config = { allowUnfree = true; }; };
  # TODO: does not work during install because tailscale is not initialized
  # + you need certificate to even be able to access it
  # internalCA = builtins.readFile (builtins.fetchurl {
  #   url = "https://vault.prod.stratos.host:8200/v1/internal/ca/pem";
  #   sha256 = "185ca789ca9d680c92a7e749bbf8612a4802c2278487caf38655b1870478824a";
  # });
in
{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./generic.nix
    ];

  # Minimal list of modules to use the EFI system partition and the YubiKey + nouveau
  boot.initrd.kernelModules = [ "vfat" "nls_cp437" "nls_iso8859-1" "usbhid" "nouveau" ];

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
}

