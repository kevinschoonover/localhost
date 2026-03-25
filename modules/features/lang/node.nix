{ ... }:
{
  flake.nixosModules.node = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      unstable.nodejs
      unstable.nodePackages.pnpm
      unstable.bun
      unstable.yarn
      unstable.nodePackages.typescript-language-server
      unstable.nodePackages.prettier
      unstable.nodePackages.vscode-langservers-extracted
    ];
  };
}
