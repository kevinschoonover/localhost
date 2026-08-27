{ ... }:
{
  flake.nixosModules.vpn =
    { pkgs, ... }:
    let
      # crowdhealth: both work VPN configs hold private keys and the employer's
      # endpoint, so they stay on disk outside this (public) repo. Nothing about
      # the tunnels is declared as a service — `vpn` runs them in the foreground
      # and tears both down when it exits.
      wireguardConfigFile = "/home/kschoon/.openvpn/Kevin-Schoonover.conf";
      openvpnConfigFile = "/home/kschoon/.openvpn/kschoonover.ovpn";

      vpn = pkgs.writeShellApplication {
        name = "vpn";
        runtimeInputs = with pkgs; [
          wireguard-tools
          openvpn
          iproute2
          gnugrep
          gnused
          # Supplies journalctl, and the `resolvconf` that wg-quick's DNS= line
          # needs: systemd ships it as a symlink to resolvectl, which is what
          # this host's resolved-based stack expects. openresolv must NOT be
          # here — it shadows that shim and errors out as disabled.
          systemd
        ];
        text = ''
          wireguard_config=${wireguardConfigFile}
          openvpn_config=${openvpnConfigFile}

          # wg-quick names the interface after the config file's basename, and
          # the real filename is both too long for an ifname and not "wg0", so
          # it is reached through a root-only symlink instead of being copied.
          link_dir=/run/vpn
          wireguard_link=$link_dir/wg0.conf

          usage() {
            cat >&2 <<'EOF'
          usage: vpn [all|wireguard|openvpn]

          Brings the work tunnels up in the foreground and streams both logs.
          Ctrl-C (or any exit) takes them back down.
          EOF
            exit 64
          }

          target=''${1:-all}
          case "$target" in
            all | wireguard | openvpn) ;;
            *)
              printf 'vpn: unknown target %s\n\n' "$target" >&2
              usage
              ;;
          esac

          # wg-quick and openvpn both need root, and re-execing keeps the whole
          # teardown under one root process rather than per-command sudo.
          if [ "$(id -u)" -ne 0 ]; then
            exec sudo -- "$0" "$@"
          fi

          want_wireguard=false
          want_openvpn=false
          case "$target" in
            all)
              want_wireguard=true
              want_openvpn=true
              ;;
            wireguard) want_wireguard=true ;;
            openvpn) want_openvpn=true ;;
          esac

          openvpn_pid=""
          kernel_log_pid=""
          wireguard_up=false

          log() { printf '[vpn] %s\n' "$1"; }

          # A child that is already gone is the expected case during teardown,
          # so a failed signal is reported but never aborts the rest of it.
          stop_child() {
            local name=$1 pid=$2 waited=0
            kill -0 "$pid" 2>/dev/null || return 0
            kill -TERM "$pid" 2>/dev/null || true
            # Bounded: 20 * 0.25s = 5s to exit cleanly, then SIGKILL.
            while [ "$waited" -lt 20 ] && kill -0 "$pid" 2>/dev/null; do
              sleep 0.25
              waited=$((waited + 1))
            done
            if kill -0 "$pid" 2>/dev/null; then
              log "$name did not exit in 5s, killing"
              kill -KILL "$pid" 2>/dev/null || true
            fi
          }

          cleanup() {
            trap - INT TERM EXIT
            log 'shutting down'
            if [ -n "$kernel_log_pid" ]; then
              stop_child 'kernel log' "$kernel_log_pid"
            fi
            if [ -n "$openvpn_pid" ]; then
              stop_child openvpn "$openvpn_pid"
            fi
            if [ "$wireguard_up" = true ]; then
              wg-quick down "$wireguard_link" || log 'wg-quick down failed'
            fi
            rm -f "$wireguard_link"
            log 'down'
          }
          trap cleanup INT TERM EXIT

          if [ "$want_wireguard" = true ]; then
            install -d -m 700 "$link_dir"
            ln -sfn "$wireguard_config" "$wireguard_link"
            wg-quick up "$wireguard_link" 2>&1 | sed -u 's/^/[wireguard] /'
            wireguard_up=true
            # WireGuard is a kernel module with no daemon, so its only running
            # log is the kernel ring buffer.
            # Process substitution rather than a pipeline so $! is journalctl's
            # own pid; killing it closes the pipe and the filters exit with it.
            journalctl --kernel --follow --since=now --output=cat \
              > >(grep --line-buffered -i wireguard | sed -u 's/^/[wireguard] /') \
              2>/dev/null &
            kernel_log_pid=$!
          fi

          if [ "$want_openvpn" = true ]; then
            openvpn --config "$openvpn_config" \
              > >(sed -u 's/^/[openvpn] /') 2>&1 &
            openvpn_pid=$!
          fi

          log "up ($target) — Ctrl-C to bring down"

          if [ -n "$openvpn_pid" ]; then
            # openvpn is the long-running process; if it dies, take everything
            # down rather than leaving a half-open tunnel behind.
            wait "$openvpn_pid" && status=0 || status=$?
            openvpn_pid=""
            log "openvpn exited with status $status"
            exit "$status"
          fi

          # WireGuard only: nothing to wait on, so hold until interrupted.
          while true; do
            sleep 3600
          done
        '';
      };
    in
    {
      services.mullvad-vpn.enable = true;
      services.tailscale.enable = true;
      services.tailscale.package = pkgs.unstable.tailscale;

      environment.systemPackages = with pkgs; [
        openvpn
        vpn
      ];
    };
}
