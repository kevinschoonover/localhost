{ inputs, ... }:
{
  flake.nixosModules.cli-utils =
    { pkgs, ... }:
    {
      imports = [ inputs.omp.nixosModules.omp ];

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

        unstable.claude-code
        unstable.kopia
        unstable.restic
        unstable.remmina
        altair
        insomnia
      ];

      programs.omp.enable = true;
    };
}
