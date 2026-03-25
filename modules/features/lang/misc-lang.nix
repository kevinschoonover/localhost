{ ... }:
{
  flake.nixosModules.misc-lang = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      unstable.tree-sitter
      ctags
      unstable.marksman
      unstable.nodePackages.yaml-language-server
      unstable.nodePackages.json-server
      unstable.nodePackages.diagnostic-languageserver
      unstable.efm-langserver
      unstable.taplo
      unstable.dockerfile-language-server
      unstable.terraform-lsp
      unstable.vacuum-go
      ansible
      unstable.ansible-lint
      unstable.copilot-language-server
    ];
  };
}
