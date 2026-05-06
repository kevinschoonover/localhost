{ ... }:
{
  flake.nixosModules.bluetooth =
    { ... }:
    {
      hardware.bluetooth.enable = true;
      hardware.bluetooth.input = {
        General = {
          IdleTimeout = 15;
        };
      };
    };
}
