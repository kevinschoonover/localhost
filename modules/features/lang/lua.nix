{ ... }:
{
  flake.nixosModules.lua = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      unstable.lua-language-server
      unstable.stylua
    ];
  };
}
