{ inputs, self, ... }:
let
  system = "x86_64-linux";
  pkgs-unstable = import inputs.nixpkgs-unstable {
    inherit system;
    config.allowUnfree = true;
  };
  pkgs-master = import inputs.nixpkgs-master {
    inherit system;
    config.allowUnfree = true;
  };
  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
    overlays = [
      (final: prev: {
        unstable = pkgs-unstable;
        master = pkgs-master;
        nil = inputs.nil.packages.${system}.nil;
      })
    ];
  };
in
{
  flake.nixosConfigurations.mothership = inputs.nixpkgs.lib.nixosSystem {
    inherit pkgs;
    modules = [
      { nixpkgs.hostPlatform = system; }
      self.nixosModules.mothershipConfiguration
    ];
  };
}
