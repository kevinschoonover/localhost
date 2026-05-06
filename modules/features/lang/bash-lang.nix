{ ... }:
{
  flake.nixosModules.bash-lang =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.unstable.bash-language-server ];
    };
}
