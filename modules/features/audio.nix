{ ... }:
{
  flake.nixosModules.audio = { pkgs, ... }: {
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      wireplumber.enable = true;
      alsa.enable = true;
      pulse.enable = true;
      jack.enable = true;
    };
    environment.systemPackages = with pkgs; [ pamixer pavucontrol ];
  };
}
