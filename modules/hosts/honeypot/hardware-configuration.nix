{ ... }:
{
  flake.nixosModules.honeypotHardware = { config, lib, pkgs, modulesPath, ... }: {
    imports = [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

    boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usbhid" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-intel" ];
    boot.extraModulePackages = [ ];
    boot.kernelParams = [
      "mitigations=off"
    ];
    boot.kernel.sysctl."net.ipv4.icmp_echo_ignore_broadcasts" = 1;

    nix.settings.max-jobs = lib.mkDefault 6;

    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-label/BOOT";
      fsType = "vfat";
    };

    # External disk holding the media/ docker-compose stack (configs and library).
    # nofail keeps boot going without it; Docker refuses to start until it is
    # mounted, because a container started first binds the empty directory
    # underneath and runs as a blank install against the root disk.
    fileSystems."/opt/appdata" = {
      device = "/dev/disk/by-uuid/86E8-882E";
      fsType = "exfat";
      options = [ "uid=1000" "gid=1000" "fmask=0022" "dmask=0022" "nofail" ];
    };
    systemd.services.docker.unitConfig.RequiresMountsFor = "/opt/appdata";

    swapDevices = [{ device = "/dev/disk/by-label/swap"; }];

    networking.useDHCP = lib.mkDefault true;

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
