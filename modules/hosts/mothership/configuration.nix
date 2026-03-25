{ inputs, self, ... }:
{
  flake.nixosModules.mothershipConfiguration = { config, pkgs, lib, ... }: {
    imports = [
      self.nixosModules.mothershipHardware

      # System fundamentals
      self.nixosModules.boot
      self.nixosModules.nix-settings
      self.nixosModules.networking
      self.nixosModules.locale
      self.nixosModules.audio
      self.nixosModules.user
      self.nixosModules.shell
      self.nixosModules.certificates

      # Desktop
      self.nixosModules.niri

      self.nixosModules.dotfiles


      # Applications
      self.nixosModules.browser
      self.nixosModules.communication
      self.nixosModules.spotify
      self.nixosModules.kitty
      self.nixosModules.neovim
      self.nixosModules.git
      self.nixosModules.tmux

      # Languages
      self.nixosModules.go
      self.nixosModules.rust
      self.nixosModules.python
      self.nixosModules.node
      self.nixosModules.lua
      self.nixosModules.nix-lang
      self.nixosModules.bash-lang
      self.nixosModules.elixir
      self.nixosModules.c-cpp
      self.nixosModules.misc-lang

      # Infrastructure & services
      self.nixosModules.infrastructure
      self.nixosModules.docker
      self.nixosModules.security
      self.nixosModules.services
      self.nixosModules.bluetooth
      self.nixosModules.vpn
      self.nixosModules.gaming
      self.nixosModules.mobile
      self.nixosModules.cli-utils
    ];

    networking.hostName = "mothership";
    system.stateVersion = "21.11";

    # LUKS + YubiKey
    boot.initrd.kernelModules = [ "vfat" "nls_cp437" "nls_iso8859-1" "usbhid" ];
    boot.initrd.luks.devices."encrypted" = {
      device = "/dev/nvme1n1p2";
      preLVM = true;
      yubikey = { slot = 2; twoFactor = false; storage.device = "/dev/nvme1n1p1"; };
    };

    networking.useDHCP = false;
    networking.interfaces.enp7s0.useDHCP = true;
    networking.interfaces.wlan0.useDHCP = true;

    # NVIDIA
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.nvidia = {
      modesetting.enable = true;
      open = false;
      package = config.boot.kernelPackages.nvidiaPackages.beta;
    };
    hardware.openrazer.enable = true;
    hardware.xpadneo.enable = true;
  };
}
