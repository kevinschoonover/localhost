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
    boot.kernelParams = [
      "mitigations=off"
      "nowatchdog"
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
