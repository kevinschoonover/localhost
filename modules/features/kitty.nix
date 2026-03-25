{ ... }:
{
  flake.nixosModules.kitty = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.unstable.kitty ];
  };
}
