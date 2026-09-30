{ inputs, ... }:
{
  flake.nixosModules.cli-utils =
    { pkgs, ... }:
    let
      # claude-code releases land on nixpkgs master days before nixos-unstable
      # catches up. Only this one package comes from master, at the commit
      # pinned in flake.nix.
      pkgs-master = import inputs.nixpkgs-master {
        inherit (pkgs.stdenv.hostPlatform) system;
        config.allowUnfree = true;
      };
    in
    {

      environment.systemPackages = with pkgs; [
        jq
        vim
        wget
        htop
        unstable.ripgrep
        unstable.fd
        unstable.eza
        unstable.bat
        unstable.croc
        step-cli
        unstable.openssl
        unstable.openssl.dev
        bitwarden-cli
        libnotify
        unzip
        vulkan-tools
        direnv
        unstable.doggo
        unstable.graphviz
        imv
        unstable.yazi
        unstable.turso-cli
        unstable.sqlite
        unstable.sqlc
        unstable.opencode
        unstable.omp

        pkgs-master.claude-code
        unstable.kopia
        unstable.restic
        unstable.remmina
        altair
        insomnia
      ];

    };
}
