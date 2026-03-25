{ ... }:
{
  flake.nixosModules.bash-lang = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.unstable.nodePackages.bash-language-server ];
  };
}
