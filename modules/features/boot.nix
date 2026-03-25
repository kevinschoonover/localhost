{ ... }:
{
  flake.nixosModules.boot = { pkgs, ... }: {
    boot.initrd.luks.yubikeySupport = true;
    boot.kernelPackages = pkgs.unstable.linuxPackages;
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
  };
}
