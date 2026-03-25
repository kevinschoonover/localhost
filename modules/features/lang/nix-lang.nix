{ ... }:
{
  flake.nixosModules.nix-lang = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.unstable.nil ];
  };
}
