{ ... }:
{
  flake.nixosModules.elixir = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.unstable.elixir ];
  };
}
