{ ... }:
{
  flake.nixosModules.browser = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.google-chrome ];
    environment.sessionVariables.DEFAULT_BROWSER = "google-chrome-stable";
  };
}
