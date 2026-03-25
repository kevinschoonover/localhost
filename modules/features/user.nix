{ ... }:
{
  flake.nixosModules.user = { ... }: {
    users.users.kschoon = {
      isNormalUser = true;
      extraGroups = [ "wheel" "video" "docker" ];
    };
    services.getty.autologinUser = "kschoon";
  };
}
