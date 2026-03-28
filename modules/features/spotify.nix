{ inputs, ... }:
{
  flake.nixosModules.spotify =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        spotify
        unstable.playerctl
        inputs.spotatui.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };
}
