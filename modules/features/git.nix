{ ... }:
{
  flake.nixosModules.git = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      unstable.git
      unstable.gh
      unstable.delta
    ];
  };
}
