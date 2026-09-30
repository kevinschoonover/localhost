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
    let
      yaziDesktop = pkgs.makeDesktopItem {
        name = "yazi";
        desktopName = "Yazi";
        exec = "${lib.getExe pkgs.unstable.kitty} -e ${lib.getExe pkgs.unstable.yazi} %U";
        mimeTypes = [ "inode/directory" ];
        terminal = false;
        categories = [
          "System"
          "FileManager"
        ];
      };
    in
    {
      # niri spawns `noctalia` from PATH, so the shell must be installed
      # wherever niri is.
      imports = [ self.nixosModules.noctalia ];

      programs.niri = {
        enable = true;
        package = self.packages.${pkgs.stdenv.hostPlatform.system}.myNiri;
      };

      xdg = {
        autostart.enable = true;
        icons.enable = true;
        portal = {
          enable = true;
          # extraPortals (gnome + gtk) are supplied by programs.niri.enable via
          # the upstream NixOS module (programs/wayland/niri.nix + wayland-session.nix).
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
        mime = {
          enable = true;
          defaultApplications = {
            "text/html" = "google-chrome.desktop";
            "x-scheme-handler/http" = "google-chrome.desktop";
            "x-scheme-handler/https" = "google-chrome.desktop";
            "x-scheme-handler/about" = "google-chrome.desktop";
            "x-scheme-handler/unknown" = "google-chrome.desktop";
            "x-scheme-handler/mailto" = "google-chrome.desktop";
            "application/pdf" = "google-chrome.desktop";
            "image/png" = "imv.desktop";
            "image/jpeg" = "imv.desktop";
            "image/gif" = "imv.desktop";
            "image/webp" = "imv.desktop";
            "image/svg+xml" = "imv.desktop";
            "inode/directory" = "yazi.desktop";
            "x-scheme-handler/slack" = "slack.desktop";
            "x-scheme-handler/discord" = "discord.desktop";
            "x-scheme-handler/spotify" = "spotify.desktop";
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
        XCURSOR_THEME = "Bibata-Modern-Classic";
        XCURSOR_SIZE = "24";
      };
      # GTK apps read icon + cursor theme from this file
      environment.etc."xdg/gtk-3.0/settings.ini".text = ''
        [Settings]
        gtk-icon-theme-name=Papirus
        gtk-cursor-theme-name=Bibata-Modern-Classic
        gtk-cursor-theme-size=24
      '';

      programs.dconf.enable = true;

      environment.systemPackages = with pkgs; [
        yaziDesktop
        papirus-icon-theme
        bibata-cursors
        brightnessctl
        wf-recorder
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
      ...
    }:
    let
      # The LG ultrawide's connector. Bound once because DRM renumbers these
      # between kernels and docks: this was DP-8, is now DP-7, and every
      # reference silently stopped matching without any error from niri.
      # Confirm with `niri msg outputs` if the layout looks wrong.
      ultrawide = "DP-7";
    in
    {
      packages.myNiri = inputs.wrapper-modules.wrappers.niri.wrap {
        inherit pkgs;
        settings = {
          spawn-at-startup = [
            # By name from PATH: the host's noctalia module wraps the binary
            # with its generated config, and the wrapper build is what
            # validates that config. Same reasoning as google-chrome below.
            "noctalia"
            (lib.getExe pkgs-unstable.kanshi)
            "sh -c 'niri msg action focus-workspace '1:code' && ${lib.getExe pkgs-unstable.kitty}'"
            [
              "spotify"
              "--enable-features=UseOzonePlatform"
              "--ozone-platform=wayland"
            ]
            # Spawned by name from PATH, like spotify/discord/slack below, so
            # this uses the single wrapped package from browser.nix rather than
            # pulling a second google-chrome into the closure. The
            # --ozone-platform=x11 flag lives in that wrapper.
            "google-chrome-stable"
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

          cursor = {
            xcursor-theme = "Bibata-Modern-Classic";
            xcursor-size = 24;
          };

          # Monitor layout: LG ultrawide to the left, laptop on the right
          # To find output names and modes: niri msg outputs
          outputs.${ultrawide} = {
            position = _: {
              props = {
                x = 0;
                y = 0;
              };
            };
          };
          outputs."eDP-1" = {
            scale = 1.5;
            position = _: {
              props = {
                x = 3840;
                y = 0;
              };
            };
          };

          input.mod-key = "Alt";
          input.keyboard.xkb.layout = "us";

          input.touchpad = {
            tap = _: { };
            natural-scroll = _: { };
          };

          layout = {
            gaps = 5;
            center-focused-column = "never";
          };

          screenshot-path = "~/Pictures/Screenshots/%Y-%m-%d_%H-%M-%S.png";

          # Named workspaces — primary workspaces open on the ultrawide
          workspaces = {
            "1:code" = {
              open-on-output = ultrawide;
            };
            "2:term" = {
              open-on-output = ultrawide;
            };
            "3" = {
              open-on-output = ultrawide;
            };
            "4" = {
              open-on-output = ultrawide;
            };
            "5" = {
              open-on-output = ultrawide;
            };
            "6" = {
              open-on-output = ultrawide;
            };
            "7:music" = {
              open-on-output = ultrawide;
            };
            "8:web" = {
              open-on-output = ultrawide;
            };
            "9:chat" = {
              open-on-output = ultrawide;
            };
          };

          # Auto-assign apps to workspaces
          # To find app-ids: niri msg windows
          window-rules = [
            {
              # Case-insensitive and anchored throughout: niri matches app-id
              # case-sensitively with an unanchored regex search, and these
              # ids do not match their binary names -- Spotify reports
              # "Spotify", Slack reports "slack", Chrome reports
              # "Google-chrome" on X11. Anchoring stops a rule for one app
              # from swallowing another's variants (e.g. -beta, -nightly).
              matches = [ { app-id = "(?i)^spotify$"; } ];
              open-on-workspace = "7:music";
            }
            {
              # Case-insensitive and anchored: running Chrome on X11 (see
              # browser.nix) means the app-id comes from WM_CLASS as
              # "Google-chrome" rather than Wayland's "google-chrome". Matching
              # both keeps this rule working if Chrome ever returns to Wayland.
              matches = [ { app-id = "(?i)^google-chrome$"; } ];
              open-on-workspace = "8:web";
            }
            {
              matches = [ { app-id = "(?i)^discord$"; } ];
              open-on-workspace = "9:chat";
            }
            {
              matches = [ { app-id = "(?i)^slack$"; } ];
              open-on-workspace = "9:chat";
            }
            {
              # noctalia's settings window is a normal toplevel; keep it
              # floating instead of tiling into the column layout.
              matches = [ { app-id = "^dev\\.noctalia\\.Noctalia$"; } ];
              open-floating = true;
              default-column-width.fixed = 1080;
              default-window-height.fixed = 920;
            }
          ];

          # https://docs.noctalia.dev/noctalia/compositor-settings/niri/
          layer-rules = [
            {
              # The blurred/tinted wallpaper copy from noctalia's [backdrop]
              # section becomes the overview backdrop.
              matches = [ { namespace = "^noctalia-backdrop"; } ];
              place-within-backdrop = true;
            }
            {
              # noctalia publishes its own blur regions (niri >= 26.04); xray
              # would sample the wallpaper instead of the windows behind them.
              matches = [ { namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd)$"; } ];
              background-effect.xray = false;
            }
            {
              matches = [ { namespace = "^noctalia-window-switcher$"; } ];
              background-effect = {
                blur = true;
                xray = false;
              };
            }
          ];

          # Lets notification actions and the launcher activate windows.
          debug.honor-xdg-activation-with-invalid-serial = _: { };

          # To list noctalia IPC commands: noctalia msg --help
          binds = {
            # Terminal
            "Mod+Return".spawn-sh = lib.getExe pkgs-unstable.kitty;

            # Close window
            "Mod+Shift+Q".close-window = _: { };

            # noctalia panels
            "Mod+D".spawn-sh = "noctalia msg panel-toggle launcher";
            "Mod+S".spawn-sh = "noctalia msg panel-toggle control-center";
            "Mod+V".spawn-sh = "noctalia msg panel-toggle clipboard";
            "Mod+Comma".spawn-sh = "noctalia msg settings-toggle";
            "Mod+Tab".spawn-sh = "noctalia msg window-switcher";

            # Wifi (iwmenu)
            "Mod+W".spawn-sh = "${lib.getExe pkgs-unstable.iwmenu} --launcher fuzzel";

            # Focus navigation (vim keys)
            "Mod+H".focus-column-left = _: { };
            "Mod+J".focus-window-down = _: { };
            "Mod+K".focus-window-up = _: { };
            "Mod+L".focus-column-right = _: { };
            "Mod+Left".focus-column-left = _: { };
            "Mod+Down".focus-window-down = _: { };
            "Mod+Up".focus-window-up = _: { };
            "Mod+Right".focus-column-right = _: { };

            # Move windows (vim keys)
            "Mod+Shift+H".move-column-left = _: { };
            "Mod+Shift+J".move-window-down = _: { };
            "Mod+Shift+K".move-window-up = _: { };
            "Mod+Shift+L".move-column-right = _: { };
            "Mod+Shift+Left".move-column-left = _: { };
            "Mod+Shift+Down".move-window-down = _: { };
            "Mod+Shift+Up".move-window-up = _: { };
            "Mod+Shift+Right".move-column-right = _: { };

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
            "Mod+N".move-workspace-to-monitor-left = _: { };
            "Mod+M".move-workspace-to-monitor-right = _: { };

            # Fullscreen
            "Mod+F".maximize-column = _: { };
            "Mod+Shift+F".fullscreen-window = _: { };

            # Floating
            "Mod+Shift+Space".toggle-window-floating = _: { };

            # Column width / resize
            "Mod+R".switch-preset-column-width = _: { };
            "Mod+Minus".set-column-width = "-10%";
            "Mod+Equal".set-column-width = "+10%";

            # Screenshots: niri's own picker on Print, noctalia's region
            # capture with the annotation editor on Mod+Shift+S.
            "Print".screenshot = _: { };
            "Shift+Print".screenshot-window = _: { };
            "Mod+Shift+S".spawn-sh = "noctalia msg screenshot-region";

            # Volume, brightness and media go through noctalia so its OSD
            # and privacy/media widgets see the change.
            "XF86AudioRaiseVolume".spawn-sh = "noctalia msg volume-up";
            "XF86AudioLowerVolume".spawn-sh = "noctalia msg volume-down";
            "XF86AudioMute".spawn-sh = "noctalia msg volume-mute";
            "XF86AudioMicMute".spawn-sh = "noctalia msg mic-mute";

            "XF86MonBrightnessUp".spawn-sh = "noctalia msg brightness-up";
            "XF86MonBrightnessDown".spawn-sh = "noctalia msg brightness-down";

            "XF86AudioPlay".spawn-sh = "noctalia msg media toggle";
            "XF86AudioNext".spawn-sh = "noctalia msg media next";
            "XF86AudioPrev".spawn-sh = "noctalia msg media previous";

            # Session menu (lock, suspend, reboot, shutdown)
            "Mod+Home".spawn-sh = "noctalia msg panel-toggle session";

            # Lock screen only
            "Mod+Shift+Home".spawn-sh = "noctalia msg session lock";

            # Quit niri
            "Mod+Shift+E".quit = _: { };

            # Reload config
            "Mod+Shift+C".spawn-sh = "niri msg action reload-config";
          };
        };
      };
    };
}
