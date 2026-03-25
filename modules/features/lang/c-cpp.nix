{ ... }:
{
  flake.nixosModules.c-cpp = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      gcc
      binutils
      unstable.cmake
      ccls
    ];
  };
}
