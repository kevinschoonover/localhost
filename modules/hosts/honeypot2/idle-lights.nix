{ ... }:
{
  # Turns honeypot2's desk lighting off when noctalia's idle screen-off fires
  # and restores it on return, so nothing needs unplugging overnight.
  #
  # The Ducky One2 Mini (3233:6301) has no host-side lighting protocol and its
  # LEDs stay lit while the port is powered, so it is powered off at its hub
  # port instead. It cannot wake the screen while off; the mouse or the laptop
  # keyboard can, and it powers back on with the resume command.
  flake.nixosModules.honeypot2IdleLights =
    { pkgs, ... }:
    let
      # Realtek RTS5411 hub in the monitor chain (USB2 half 0bda:5411, USB3
      # half 0bda:0411). uhubctl switches both halves of the port together.
      duckyHub = {
        location = "1-2.2";
        port = "2";
      };
      frameworkKeyboard = {
        vid = "32ac";
        pid = "0012";
      };
      razerMouse = {
        device = "Razer Viper Ultimate";
        # OpenRGB cannot read this mouse's current mode (it reports Direct
        # regardless), and restoring a saved profile left it dark, so the
        # resume command sets this mode explicitly.
        mode = "Spectrum Cycle";
      };

      idleLights = pkgs.writeShellApplication {
        name = "idle-lights";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.uhubctl
          pkgs.qmk_hid
          pkgs.openrgb
        ];
        # The device functions run through `step "label" fn`, which shellcheck
        # cannot see, so it reports them as never invoked.
        excludeShellChecks = [ "SC2329" ];
        text = ''
          state="''${XDG_RUNTIME_DIR:?}/idle-lights"
          # Present while the lights are off; guards the saved levels so a
          # second `off` cannot overwrite them with the already-dark values.
          off_marker="$state/off"
          backlight_file="$state/framework-backlight"
          failed=0

          # Every device is independent: one unplugged or failing device must
          # not leave the others dark, so failures are reported and counted.
          # Every external call is bounded; a wedged device must not hang the
          # idle command (and with it, the screen coming back on).
          limit=30

          step() {
            local label="$1"
            shift
            if ! "$@"; then
              echo "idle-lights: $label failed" >&2
              failed=1
            fi
          }

          qmk() {
            timeout "$limit" qmk_hid --vid ${frameworkKeyboard.vid} --pid ${frameworkKeyboard.pid} via --backlight "$@"
          }

          save_backlight() {
            local reply level
            reply="$(qmk)" || return 1
            level="''${reply#Brightness: }"
            level="''${level%\%}"
            if [[ ! "$level" =~ ^[0-9]+$ ]] || ((level > 100)); then
              echo "idle-lights: unexpected backlight reply: $reply" >&2
              return 1
            fi
            printf '%s\n' "$level" >"$backlight_file"
          }

          restore_backlight() {
            [ -f "$backlight_file" ] || return 0
            qmk "$(<"$backlight_file")" >/dev/null
          }

          ducky() {
            timeout "$limit" uhubctl --location ${duckyHub.location} --ports ${duckyHub.port} --action "$1"
          }

          case "''${1-}" in
            off)
              if [ -e "$off_marker" ]; then
                exit 0
              fi
              mkdir -p "$state"
              step "save Framework keyboard backlight" save_backlight
              touch "$off_marker"
              step "Framework keyboard backlight off" qmk 0
              step "Razer lighting off" timeout "$limit" openrgb --noautoconnect --device "${razerMouse.device}" --mode off
              step "Ducky port power off" ducky off
              ;;
            on)
              if [ ! -e "$off_marker" ]; then
                exit 0
              fi
              # Keyboard first: it is the one that cannot type while dark.
              step "Ducky port power on" ducky on
              step "restore Framework keyboard backlight" restore_backlight
              step "Razer lighting on" timeout "$limit" openrgb --noautoconnect --device "${razerMouse.device}" --mode "${razerMouse.mode}"
              # Keep the saved levels until a fully clean restore, so the next
              # `on` retries instead of forgetting what to restore.
              if [ "$failed" -eq 0 ]; then
                rm -f "$off_marker" "$backlight_file"
              fi
              ;;
            *)
              echo "usage: idle-lights off|on" >&2
              exit 2
              ;;
          esac

          exit "$failed"
        '';
      };
    in
    {
      environment.systemPackages = [ idleLights ];

      # Lets the seat user run idle-lights without sudo, scoped to this hub:
      # uhubctl opens the hub's device node to find it, then switches power
      # through the kernel's per-port sysfs `disable` file.
      services.udev.extraRules = ''
        SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="0bda", ATTR{idProduct}=="5411|0411", GROUP="users", MODE="0660"
        ACTION=="add", SUBSYSTEM=="usb", DRIVER=="hub", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="5411|0411", RUN+="${pkgs.bash}/bin/sh -c 'chgrp users $sys$devpath/*-port*/disable && chmod 0664 $sys$devpath/*-port*/disable'"
      '';
      # OpenRGB's own rules grant the seat user its devices (and silence its
      # "udev rules are not installed" warning on every call).
      services.udev.packages = [ pkgs.openrgb ];

      localhost.noctalia.settings.idle.behavior.screen-off = {
        action = "command";
        command = "noctalia msg dpms-off; idle-lights off";
        resume_command = "noctalia msg dpms-on; idle-lights on";
      };
    };
}
