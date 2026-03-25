{ ... }:
{
  flake.nixosModules.communication = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      unstable.discord
      unstable.slack
    ];
  };
}
