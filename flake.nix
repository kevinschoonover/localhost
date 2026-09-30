{
  description = "nixos flake configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Pinned to a commit so `nix flake update` never drags master forward; only
    # claude-code is taken from it (cli-utils.nix). Bump the rev by hand.
    nixpkgs-master.url = "github:NixOS/nixpkgs/05100e1c8e95aa12e9ca433113b2ebbe357baed4";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    nil.url = "github:oxalica/nil";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
