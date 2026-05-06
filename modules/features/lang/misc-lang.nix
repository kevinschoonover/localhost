{ ... }:
{
  flake.nixosModules.misc-lang =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        unstable.tree-sitter
        ctags
        unstable.marksman
        unstable.yaml-language-server
        unstable.json-server
        unstable.diagnostic-languageserver
        unstable.efm-langserver
        unstable.tombi
        unstable.dockerfile-language-server
        unstable.terraform-lsp
        unstable.vacuum-go
        ansible
        unstable.ansible-lint
        unstable.copilot-language-server
      ];
    };
}
