{ ... }:
{
  flake.nixosModules.locale = { pkgs, lib, ... }: {
    time.timeZone = "America/Vancouver";
    i18n.defaultLocale = "en_US.UTF-8";
    console = { font = "FiraCode Nerd Font"; keyMap = "us"; };
    fonts.packages =
      [] ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);
  };
}
