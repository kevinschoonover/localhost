{ ... }:
{
  flake.nixosModules.python = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      unstable.uv
      poetry
      unstable.ruff
      unstable.basedpyright
    ];
  };
}
