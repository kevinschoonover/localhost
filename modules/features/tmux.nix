{ ... }:
{
  flake.nixosModules.tmux = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.unstable.tmux ];
  };
}
