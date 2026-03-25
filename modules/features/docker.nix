{ ... }:
{
  flake.nixosModules.docker = { pkgs, ... }: {
    virtualisation.docker = {
      enable = true;
      package = pkgs.unstable.docker;
      autoPrune.enable = true;
      extraOptions = ''--insecure-registry "https://localhost:5002" --insecure-registry "https://100.85.82.116:5000"'';
    };
    environment.systemPackages = with pkgs; [ docker-compose unstable.earthly ];
    programs.virt-manager.enable = true;
    virtualisation.spiceUSBRedirection.enable = true;
  };
}
