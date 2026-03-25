{ ... }:
{
  flake.nixosModules.nix-settings = { pkgs, ... }: {
    nix = {
      package = pkgs.nixVersions.stable;
      settings = {
        experimental-features = [ "nix-command" "flakes" ];
        auto-optimise-store = true;
      };
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };
    };
    system.autoUpgrade.enable = true;
  };
}
