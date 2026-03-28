{ self, inputs, ... }:
let
  pkgs-unstable = import inputs.nixpkgs-unstable {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
in
{
  flake.nixosModules.niri =
    { pkgs, lib, ... }:
    {
      programs.niri = {
        enable = true;
        package = self.packages.${pkgs.stdenv.hostPlatform.system}.myNiri;
      };

      xdg = {
        autostart.enable = true;
        icons.enable = true;
        portal = {
          enable = true;
          extraPortals = [
            pkgs.xdg-desktop-portal-gnome
            pkgs.xdg-desktop-portal-gtk
          ];
          config.niri = {
            default = [
              "gnome"
              "gtk"
            ];
            "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
            "org.freedesktop.impl.portal.Screencast" = [ "gnome" ];
            "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
          };
        };
      };

      environment.sessionVariables = {
        MOZ_ENABLE_WAYLAND = "1";
        XDG_CURRENT_DESKTOP = "niri";
        XDG_SESSION_TYPE = "wayland";
      };

      security.polkit.enable = true;

      # Auto-login via greetd — replaces getty, handles PAM/dbus/VT properly
      services.greetd = {
        enable = true;
        settings.default_session = {
          command = "niri-session";
          user = "kschoon";
        };
      };

      # Icon theme for Qt apps (noctalia), GTK apps (blueman), and freedesktop
      environment.variables = {
        XDG_ICON_THEME = "Papirus";
        QT_ICON_THEME_NAME = "Papirus";
      };
      # GTK apps read icon theme from this file
      environment.etc."xdg/gtk-3.0/settings.ini".text = ''
        [Settings]
        gtk-icon-theme-name=Papirus
      '';

      programs.dconf.enable = true;

      environment.systemPackages = with pkgs; [
        papirus-icon-theme
        brightnessctl
        unstable.wf-recorder
        gpu-screen-recorder
        gpu-screen-recorder-gtk
        unstable.iwmenu
        unstable.grim
        unstable.slurp
        unstable.wl-clipboard
        unstable.kanshi
        unstable.xwayland-satellite
        unstable.fuzzel
      ];
    };

  perSystem =
    {
      pkgs,
      lib,
      self',
      ...
    }:
    let
      noctaliaExe = lib.getExe self'.packages.myNoctalia;
    in
    {
      packages.myNiri = inputs.wrapper-modules.wrappers.niri.wrap {
        inherit pkgs;
        settings = {
          spawn-at-startup = [
            (lib.getExe self'.packages.myNoctalia)
            (lib.getExe pkgs-unstable.kanshi)
            "sh -c 'niri msg action focus-workspace '1:code' && ${lib.getExe pkgs-unstable.kitty}'"
            [
              "spotify"
              "--enable-features=UseOzonePlatform"
              "--ozone-platform=wayland"
            ]
            (lib.getExe pkgs-unstable.google-chrome)
            [
              "discord"
              "--use-gl=desktop"
              "--enable-features=UseOzonePlatform"
              "--ozone-platform=wayland"
            ]
            [
              "slack"
              "--enable-features=UseOzonePlatform"
              "--ozone-platform=wayland"
            ]
          ];

          xwayland-satellite.path = lib.getExe pkgs-unstable.xwayland-satellite;

          # Monitor layout: LG ultrawide to the left, laptop on the right
          # To find output names and modes: niri msg outputs
          outputs."DP-8" = {
            position = {
              _attrs = {
                x = 0;
                y = 0;
              };
            };
          };
          outputs."eDP-1" = {
            scale = 1.5;
            position = {
              _attrs = {
                x = 3840;
                y = 0;
              };
            };
          };

          input.mod-key = "Alt";
          input.keyboard.xkb.layout = "us";

          input.touchpad = {
            tap = null;
            natural-scroll = null;
          };

          layout = {
            gaps = 5;
            center-focused-column = "never";
          };

          screenshot-path = "~/Pictures/Screenshots/%Y-%m-%d_%H-%M-%S.png";

          # Named workspaces — primary workspaces open on ultrawide (DP-8)
          workspaces = {
            "1:code" = {
              open-on-output = "DP-8";
            };
            "2:term" = {
              open-on-output = "DP-8";
            };
            "3" = {
              open-on-output = "DP-8";
            };
            "4" = {
              open-on-output = "DP-8";
            };
            "5" = {
              open-on-output = "DP-8";
            };
            "6" = {
              open-on-output = "DP-8";
            };
            "7:music" = {
              open-on-output = "DP-8";
            };
            "8:web" = {
              open-on-output = "DP-8";
            };
            "9:chat" = {
              open-on-output = "DP-8";
            };
          };

          # Auto-assign apps to workspaces
          # To find app-ids: niri msg windows
          window-rules = [
            {
              matches = [ { app-id = "spotify"; } ];
              open-on-workspace = "7:music";
            }
            {
              matches = [ { app-id = "google-chrome"; } ];
              open-on-workspace = "8:web";
            }
            {
              matches = [ { app-id = "discord"; } ];
              open-on-workspace = "9:chat";
            }
            {
              matches = [ { app-id = "Slack"; } ];
              open-on-workspace = "9:chat";
            }
          ];

          # To list noctalia IPC targets/functions: noctalia-shell ipc show
          binds = {
            # Terminal
            "Mod+Return".spawn-sh = lib.getExe pkgs-unstable.kitty;

            # Close window
            "Mod+Shift+Q".close-window = null;

            # Application launcher (noctalia)
            "Mod+D".spawn-sh = "${noctaliaExe} ipc call launcher toggle";

            # Wifi (iwmenu)
            "Mod+W".spawn-sh = "${lib.getExe pkgs-unstable.iwmenu} --launcher fuzzel";

            # Focus navigation (vim keys)
            "Mod+H".focus-column-left = null;
            "Mod+J".focus-window-down = null;
            "Mod+K".focus-window-up = null;
            "Mod+L".focus-column-right = null;
            "Mod+Left".focus-column-left = null;
            "Mod+Down".focus-window-down = null;
            "Mod+Up".focus-window-up = null;
            "Mod+Right".focus-column-right = null;

            # Move windows (vim keys)
            "Mod+Shift+H".move-column-left = null;
            "Mod+Shift+J".move-window-down = null;
            "Mod+Shift+K".move-window-up = null;
            "Mod+Shift+L".move-column-right = null;
            "Mod+Shift+Left".move-column-left = null;
            "Mod+Shift+Down".move-window-down = null;
            "Mod+Shift+Up".move-window-up = null;
            "Mod+Shift+Right".move-column-right = null;

            # Workspaces
            "Mod+1".focus-workspace = "1:code";
            "Mod+2".focus-workspace = "2:term";
            "Mod+3".focus-workspace = "3";
            "Mod+4".focus-workspace = "4";
            "Mod+5".focus-workspace = "5";
            "Mod+6".focus-workspace = "6";
            "Mod+7".focus-workspace = "7:music";
            "Mod+8".focus-workspace = "8:web";
            "Mod+9".focus-workspace = "9:chat";

            # Move window to workspace
            "Mod+Shift+1".move-column-to-workspace = "1:code";
            "Mod+Shift+2".move-column-to-workspace = "2:term";
            "Mod+Shift+3".move-column-to-workspace = "3";
            "Mod+Shift+4".move-column-to-workspace = "4";
            "Mod+Shift+5".move-column-to-workspace = "5";
            "Mod+Shift+6".move-column-to-workspace = "6";
            "Mod+Shift+7".move-column-to-workspace = "7:music";
            "Mod+Shift+8".move-column-to-workspace = "8:web";
            "Mod+Shift+9".move-column-to-workspace = "9:chat";

            # Move workspace to monitor
            "Mod+N".move-workspace-to-monitor-left = null;
            "Mod+M".move-workspace-to-monitor-right = null;

            # Fullscreen
            "Mod+F".maximize-column = null;
            "Mod+Shift+F".fullscreen-window = null;

            # Floating
            "Mod+Shift+Space".toggle-window-floating = null;

            # Column width / resize
            "Mod+R".switch-preset-column-width = null;
            "Mod+Minus".set-column-width = "-10%";
            "Mod+Equal".set-column-width = "+10%";

            # Screenshots
            "Print".screenshot = null;
            "Shift+Print".screenshot-window = null;

            # Volume
            "XF86AudioRaiseVolume".spawn-sh = "pamixer -i 5";
            "XF86AudioLowerVolume".spawn-sh = "pamixer -d 5";
            "XF86AudioMute".spawn-sh = "pamixer -t";

            # Brightness
            "XF86MonBrightnessUp".spawn-sh = "brightnessctl set +5%";
            "XF86MonBrightnessDown".spawn-sh = "brightnessctl set 5%-";

            # Media
            "XF86AudioPlay".spawn-sh = "playerctl play-pause";
            "XF86AudioNext".spawn-sh = "playerctl next";
            "XF86AudioPrev".spawn-sh = "playerctl previous";

            # Session menu (lock, suspend, reboot, shutdown)
            "Mod+Home".spawn-sh = "${noctaliaExe} ipc call sessionMenu toggle";

            # Lock screen only
            "Mod+Shift+Home".spawn-sh = "${noctaliaExe} ipc call lockScreen lock";

            # Quit niri
            "Mod+Shift+E".quit = null;

            # Reload config
            "Mod+Shift+C".spawn-sh = "niri msg action reload-config";
          };
        };
      };
    };
}
