{ ... }:
{
  flake.nixosModules.user = { ... }: {
    users.users.kschoon = {
      isNormalUser = true;
      extraGroups = [ "wheel" "video" "docker" ];
    };
    # Getty autologin disabled — niri.nix uses autologin systemd service instead
  };
}
