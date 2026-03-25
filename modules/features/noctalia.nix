{ inputs, ... }:
let
  pkgs-unstable = import inputs.nixpkgs-unstable {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
in
{
  perSystem =
    { pkgs, ... }:
    {
      packages.myNoctalia = inputs.wrapper-modules.wrappers.noctalia-shell.wrap {
        inherit pkgs;
        package = pkgs-unstable.noctalia-shell;
        settings = (builtins.fromJSON (builtins.readFile ./noctalia.json)).settings;
      };
    };
}
