{ ... }:
{
  flake.nixosModules.honeypot2Hardware = { config, lib, pkgs, modulesPath, ... }: {
    imports = [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

    boot.initrd.availableKernelModules = [
      "nvme" "xhci_pci" "thunderbolt" "usbhid" "uas" "usb_storage" "sd_mod"
    ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-amd" ];
    boot.extraModulePackages = [ ];
    # Workaround for graphical glitches on the Framework 16 internal eDP
    # panel (tearing, random dimming, dark flickers) triggered by GPU-
    # accelerated browser engines under Wayland — Tauri/webkit2gtk and
    # Chromium under Playwright are both confirmed triggers. External DP
    # outputs are unaffected because PSR/ABM/MPO are eDP-only features.
    #
    # nixos-hardware/framework/16-inch/common/amd.nix already sets
    # `amdgpu.dcdebugmask=0x10` (PSR1 only). The kernel uses the LAST value
    # for duplicate args, so we use `lib.mkAfter` on the override list to
    # ensure our wider mask appends after the upstream entry and wins.
    # Verify after rebuild with:
    #   cat /proc/cmdline   # last amdgpu.dcdebugmask= value should be 0x610
    #   cat /sys/module/amdgpu/parameters/dcdebugmask   # should print 1552
    #
    # dcdebugmask bits (drivers/gpu/drm/amd/include/amd_shared.h):
    #   0x010 = DC_DISABLE_PSR      (Panel Self-Refresh)
    #   0x200 = DC_DISABLE_PSR_SU   (PSR Selective Update — Phoenix uses this)
    #   0x400 = DC_DISABLE_MPO      (Multi-Plane Overlay)
    #   0x610 = all three combined
    #
    # abmlevel=0 disables Adaptive Backlight Management, which causes the
    # random dimming/darkening as the panel auto-adjusts to scene content.
    #
    # Debug commands if glitches return:
    #   sudo dmesg -T | grep -iE 'amdgpu|drm|psr|dmcub|dcn'
    #   sudo journalctl -k -b 0 | grep -iE 'gpu hang|ring.*reset|page fault|MES'
    #   find /sys/kernel/debug/dri -name '*psr*'  # locate PSR state files
    #   sudo cat /sys/kernel/debug/dri/1/eDP-1/psr_state   # 0=off, >0=active
    # Reset panel state without reboot (clears mid-day corruption):
    #   niri msg output eDP-1 off; sleep 1; niri msg output eDP-1 on
    # Browser-side isolation tests (no rebuild needed):
    #   WEBKIT_DISABLE_DMABUF_RENDERER=1 <tauri-app>
    #   LIBGL_ALWAYS_SOFTWARE=1 npx playwright test
    boot.kernelParams = lib.mkMerge [
      [
        "mitigations=off"
        "nowatchdog"
      ]
      (lib.mkAfter [
        "amdgpu.dcdebugmask=0x610"
        "amdgpu.abmlevel=0"
      ])
    ];
    boot.kernel.sysctl = {
      "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
      "vm.dirty_writeback_centisecs" = 1500;
    };

    boot.extraModprobeConfig = ''
      options usbcore use_both_schemes=y
    '';

    nix.settings.max-jobs = lib.mkDefault 16;

    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-label/BOOT";
      fsType = "vfat";
    };

    swapDevices = [{ device = "/dev/disk/by-label/swap"; }];

    networking.useDHCP = lib.mkDefault false;
    networking.interfaces.wlan0.useDHCP = lib.mkDefault true;

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
