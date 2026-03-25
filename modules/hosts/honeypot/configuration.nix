{ inputs, self, ... }:
{
  flake.nixosModules.honeypotConfiguration = { config, pkgs, lib, ... }: {
    imports = [
      inputs.nixos-hardware.nixosModules.dell-xps-13-9380
      self.nixosModules.honeypotHardware

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
      self.nixosModules.sway
      self.nixosModules.dotfiles
      self.nixosModules.redshift

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

    networking.hostName = "honeypot";
    system.stateVersion = "23.05";
  };
}
