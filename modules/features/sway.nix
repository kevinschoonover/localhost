{ ... }:
{
  flake.nixosModules.sway = { pkgs, ... }: {
    environment.sessionVariables = {
      MOZ_ENABLE_WAYLAND = "1";
      XDG_CURRENT_DESKTOP = "sway";
      XDG_SESSION_TYPE = "wayland";
    };

    environment.loginShellInit = ''
      if [ "$(tty)" = "/dev/tty1" ]; then
        echo "============================" >> ~/.sway.log
        echo "Starting sway session at $(date)" >> ~/.sway.log
        echo "============================" >> ~/.sway.log
        exec sway >> ~/.sway.log 2>&1
      fi
    '';

    xdg = {
      autostart.enable = true;
      icons.enable = true;
      portal = {
        xdgOpenUsePortal = false;
        enable = true;
        extraPortals = [
          pkgs.xdg-desktop-portal
          pkgs.xdg-desktop-portal-gtk
          pkgs.xdg-desktop-portal-wlr
        ];
        config.sway = {
          default = [ "gtk" ];
          "org.freedesktop.impl.portal.OpenURI" = "gtk";
          "org.freedesktop.impl.portal.Screencast" = "wlr";
          "org.freedesktop.impl.portal.Screenshot" = "wlr";
          "org.freedesktop.impl.portal.GlobalShortcuts" = "gtk";
        };
      };
    };

    programs.sway = {
      enable = true;
      package = pkgs.unstable.sway;
      extraPackages = with pkgs; [
        unstable.xdg-utils unstable.swaylock unstable.swayidle
        unstable.waybar unstable.wl-clipboard unstable.mako
        unstable.alacritty unstable.dmenu unstable.bemenu
        unstable.grim unstable.slurp unstable.kanshi
      ];
    };

    environment.systemPackages = with pkgs; [
      brightnessctl
      unstable.wf-recorder
      unstable.iwmenu
    ];
  };
}
