{ ... }:
{
  flake.nixosModules.bluetooth = { ... }: {
    hardware.bluetooth.enable = true;
    # Blueman removed — noctalia handles bluetooth via its control center panel
  };
}
