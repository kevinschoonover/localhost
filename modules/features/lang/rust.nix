{ ... }:
{
  flake.nixosModules.rust = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      unstable.rustup
      unstable.rust-analyzer
    ];
  };
}
