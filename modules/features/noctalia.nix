{ inputs, ... }:
let
  pkgs-unstable = import inputs.nixpkgs-unstable {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
in
{
  # Noctalia v5 reads every *.toml in $NOCTALIA_CONFIG_HOME/noctalia/, sorted
  # by name and merged. The shared base config ships as 00-base.toml and each
  # host's `localhost.noctalia.settings` lands on top as 50-host.toml. GUI edits
  # never touch either: they go to ~/.local/state/noctalia/settings.toml.
  flake.nixosModules.noctalia =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.localhost.noctalia;
      tomlFormat = pkgs.formats.toml { };
      noctalia = pkgs-unstable.noctalia;

      hostSettings = tomlFormat.generate "noctalia-host.toml" cfg.settings;

      configHome =
        pkgs.runCommand "noctalia-config-home"
          {
            nativeBuildInputs = [ noctalia ];
          }
          ''
            install -Dm444 ${./noctalia.toml} $out/noctalia/00-base.toml
            install -Dm444 ${hostSettings} $out/noctalia/50-host.toml

            # `validate` exits 0 on unknown keys and bad enum values (warnings).
            # A typo would then ship silently, so any warning fails the build.
            noctalia config validate $out/noctalia | tee validate.log
            if grep -q '^WARN' validate.log; then
              echo "noctalia config has warnings; refusing to build" >&2
              exit 1
            fi
          '';

      configured = pkgs.symlinkJoin {
        name = "noctalia-configured-${noctalia.version}";
        paths = [ noctalia ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/noctalia --set NOCTALIA_CONFIG_HOME ${configHome}
        '';
        passthru = {
          inherit configHome;
          inherit (noctalia) version;
        };
        meta = noctalia.meta // {
          mainProgram = "noctalia";
        };
      };

      # Run by noctalia's [idle.behavior.bluetooth-off] (noctalia.toml). These
      # hosts rarely suspend, so nothing else ever drops Bluetooth links and
      # headphones stay connected, and draining, for as long as they are on.
      # `start` hands off to a background watcher that disconnects every
      # connected device not carrying live audio, rechecking until the
      # devices are gone or the user is back; `stop` ends it.
      bluetoothIdle = pkgs.writeShellApplication {
        name = "bluetooth-idle";
        runtimeInputs = [
          pkgs.bluez
          pkgs.coreutils
          pkgs.jq
          pkgs.pipewire
          pkgs.systemd
          pkgs.util-linux
        ];
        text = ''
          state="''${XDG_RUNTIME_DIR:?}/bluetooth-idle"
          # Present while the session is idle; the watcher checks it before
          # every disconnect so a returning user never loses a device.
          idle_marker="$state/idle"
          pid_file="$state/watcher.pid"
          interval_seconds=60
          # 12 hours of rechecks while audio keeps a device in use.
          max_checks=720

          connected_devices() {
            local listing kind mac
            listing="$(timeout 10 bluetoothctl devices Connected)" || return 1
            while read -r kind mac _; do
              if [ "$kind" = Device ]; then
                printf '%s\n' "$mac"
              fi
            done <<<"$listing"
          }

          # A device is in use while any of its PipeWire nodes (playback or
          # microphone) is running. Fails closed: if PipeWire cannot be read,
          # the device counts as in use and stays connected.
          in_use() {
            local dump
            if ! dump="$(timeout 10 pw-dump)"; then
              echo "pw-dump failed; keeping $1 connected" >&2
              return 0
            fi
            jq -e --arg mac "''${1//:/_}" '
              any(.[];
                .type == "PipeWire:Interface:Node"
                and ((.info.props["node.name"] // "") | startswith("bluez_") and contains($mac))
                and .info.state == "running")
            ' <<<"$dump" >/dev/null
          }

          watch() {
            local check macs mac
            printf '%s\n' "$$" >"$pid_file"
            for ((check = 0; check < max_checks; check++)); do
              if ! macs="$(connected_devices)"; then
                echo "bluetoothctl failed; retrying" >&2
              elif [ -z "$macs" ]; then
                rm -f "$idle_marker" "$pid_file"
                exit 0
              else
                while read -r mac; do
                  [ -e "$idle_marker" ] || exit 0
                  if in_use "$mac"; then
                    echo "keeping $mac: audio is running"
                  elif ! timeout 20 bluetoothctl disconnect "$mac" >/dev/null; then
                    echo "disconnect $mac failed" >&2
                  else
                    echo "disconnected $mac"
                  fi
                done <<<"$macs"
              fi
              sleep "$interval_seconds"
              [ -e "$idle_marker" ] || exit 0
            done
            echo "giving up after $max_checks checks" >&2
            rm -f "$pid_file"
          }

          watcher_running() {
            [ -f "$pid_file" ] && kill -0 "$(<"$pid_file")" 2>/dev/null
          }

          case "''${1-}" in
            start)
              mkdir -p "$state"
              touch "$idle_marker"
              if watcher_running; then
                exit 0
              fi
              # Detached so noctalia's command returns at once; output lands in
              # the journal under `bluetooth-idle`.
              setsid --fork systemd-cat --identifier=bluetooth-idle "$0" watch </dev/null
              ;;
            watch)
              watch
              ;;
            stop)
              rm -f "$idle_marker"
              if watcher_running; then
                kill "$(<"$pid_file")"
              fi
              rm -f "$pid_file"
              ;;
            *)
              echo "usage: bluetooth-idle start|stop" >&2
              exit 2
              ;;
          esac
        '';
      };
    in
    {
      options.localhost.noctalia = {
        settings = lib.mkOption {
          type = tomlFormat.type;
          default = { };
          example = lib.literalExpression ''
            {
              idle.behavior.suspend.enabled = false;
            }
          '';
          description = ''
            Host-specific noctalia settings, merged on top of noctalia.toml.
            Same TOML schema as https://docs.noctalia.dev/noctalia/configuration/.
          '';
        };

        package = lib.mkOption {
          type = lib.types.package;
          readOnly = true;
          default = configured;
          description = "noctalia wrapped with this host's generated config directory.";
        };
      };

      config = {
        environment.systemPackages = [
          cfg.package
          bluetoothIdle
        ];

        # noctalia's control center and widgets talk to UPower and BlueZ. The
        # network widget needs no switch: noctalia falls back from NetworkManager
        # to wpa_supplicant to iwd, which these hosts run (networking.nix).
        services.upower.enable = true;
        hardware.bluetooth.enable = true;
      };
    };
}
