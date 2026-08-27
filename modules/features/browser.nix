{ ... }:
{
  flake.nixosModules.browser = { pkgs, ... }: {
    # Chrome runs on X11 through xwayland-satellite, not native Wayland.
    #
    # On native Wayland under niri, Chrome's tab-modal dialogs (the
    # "Leave site?" prompt from beforeunload) render as an unpainted black
    # rectangle once the window has moved between outputs of differing scale
    # (eDP-1 at 1.5, DP-7 at 1.0). The dialog still takes input, it just never
    # paints, and there is no way to accept or cancel.
    #
    # Traced to Chrome's wp_viewporter path: after the migration Chrome keeps
    # painting the page into wl_surface#28 at full refresh (22 consecutive
    # attach/damage/commit cycles ~8.3ms apart, zero stalled frame callbacks)
    # but never composites the dialog into the buffer it submits, so the
    # compositor has nothing to show. Ruled out by testing: niri frame-callback
    # starvation, GPU compositing, WaylandFractionalScaleV1,
    # WaylandOverlayDelegation, WaylandSyncobjReleaseTimeline. Chrome drives
    # all scaling through wp_viewporter (set_buffer_scale count is 0), and X11
    # never touches that protocol, which is why it is unaffected.
    #
    # Cost: X11 has a single global scale factor, so Chrome is crisp on DP-7
    # (scale 1) and undersized on the laptop panel (scale 1.5). Adding
    # --force-device-scale-factor=1.5 flips which display looks correct.
    #
    # Revert to native Wayland once the Chromium bug is fixed.
    # Unstable, matching what niri spawns at startup. The flag lives here in the
    # wrapper rather than on the spawn command so there is exactly one Chrome
    # package in the closure and one place to change its flags.
    environment.systemPackages = [
      (pkgs.unstable.google-chrome.override {
        commandLineArgs = "--ozone-platform=x11";
      })
    ];
    environment.sessionVariables.DEFAULT_BROWSER = "google-chrome-stable";
  };
}
