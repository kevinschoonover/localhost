{ ... }:
{
  flake.nixosModules.services = { pkgs, ... }: {
    services.fstrim.enable = true;
    services.fwupd.enable = true;
    services.upower.enable = true;
    services.hardware.bolt.enable = true;
    services.auto-cpufreq.enable = true;
    services.auto-cpufreq.settings = {
      battery = { governor = "powersave"; turbo = "never"; };
      charger = { governor = "performance"; turbo = "auto"; };
    };
  };
}
