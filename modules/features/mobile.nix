{ ... }:
{
  flake.nixosModules.mobile = { pkgs, ... }: {
    services.usbmuxd = {
      enable = true;
      package = pkgs.unstable.usbmuxd2;
    };
    environment.systemPackages = with pkgs; [
      android-tools
      libimobiledevice
    ];
  };
}
