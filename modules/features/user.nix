{ ... }:
{
  flake.nixosModules.user = { ... }: {
    users.users.kschoon = {
      isNormalUser = true;
      extraGroups = [ "wheel" "video" "networkmanager" "docker" ];
    };
    services.getty.autologinUser = "kschoon";
  };
}
