{ ... }:
{
  flake.nixosModules.boot = { pkgs, ... }: {
    boot.initrd.luks.yubikeySupport = true;
    boot.kernelPackages = pkgs.unstable.linuxPackages_latest;
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
  };
}
