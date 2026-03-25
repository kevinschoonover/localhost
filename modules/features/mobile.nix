{ ... }:
{
  flake.nixosModules.mobile = { pkgs, ... }: {
    programs.adb.enable = true;
    users.users.kschoon.extraGroups = [ "adbusers" ];
    services.usbmuxd = { enable = true; package = pkgs.unstable.usbmuxd2; };
    environment.systemPackages = with pkgs; [ android-tools libimobiledevice ];
  };
}
