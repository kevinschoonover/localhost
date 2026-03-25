{ ... }:
{
  flake.nixosModules.go = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      unstable.go
      unstable.gopls
      unstable.gofumpt
      unstable.go-tools
      unstable.gotools
      unstable.errcheck
      unstable.air
      unstable.delve
      unstable.golangci-lint
      unstable.golangci-lint-langserver
    ];
  };
}
