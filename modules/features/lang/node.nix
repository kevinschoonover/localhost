{ ... }:
{
  flake.nixosModules.node =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        unstable.nodejs
        unstable.bun
        unstable.yarn
        unstable.typescript-language-server
        unstable.prettier
        unstable.vscode-langservers-extracted
      ];
    };
}
