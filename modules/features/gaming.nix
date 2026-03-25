{ ... }:
{
  flake.nixosModules.gaming = { pkgs, ... }: {
    programs.steam.enable = true;
    hardware.steam-hardware.enable = true;
    hardware.graphics.enable = true;
    hardware.graphics.extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];
    environment.systemPackages = [ pkgs.unstable.prismlauncher ];
  };
}
