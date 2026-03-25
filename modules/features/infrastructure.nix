{ ... }:
{
  flake.nixosModules.infrastructure = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      unstable.vault
      unstable.nomad
      unstable.consul
      unstable.consul-template
      unstable.envconsul
      unstable.packer
      unstable.pulumi-bin
      unstable.google-cloud-sdk
      unstable.awscli2
      turbo
    ];
  };
}
