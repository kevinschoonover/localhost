{ ... }:
{
  flake.nixosModules.redshift = { pkgs, ... }: {
    location.latitude = 47.6;
    location.longitude = -122.3;
    services.redshift = {
      enable = true;
      package = pkgs.gammastep;
    };
  };
}
