{ ... }:
{
  flake.nixosModules.nix-settings = { pkgs, ... }: {
    nix = {
      package = pkgs.nixVersions.stable;
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        auto-optimise-store = true;
        # omp's flake asks for this cache; a dependency flake's nixConfig is
        # ignored, so it has to be declared here to take effect. Covers the
        # rust-overlay/bun2nix toolchains omp pulls in, not omp itself.
        extra-substituters = [ "https://nix-community.cachix.org" ];
        extra-trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
        trusted-users = [
          "root"
          "kschoon"
        ];
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
