{ ... }:
{
  flake.nixosModules.vpn = { pkgs, ... }: {
    services.mullvad-vpn.enable = true;
    services.tailscale.enable = true;
    services.tailscale.package = pkgs.unstable.tailscale;
  };
}
