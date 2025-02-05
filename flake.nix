{
  nixConfig = {
    substituters = [
      "https://esp32-dev-nix.cachix.org?priority=10"
      "https://cache.nixos.org?priority=15"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "esp32-dev-nix.cachix.org-1:m6Jnzg6P2tl5KwKhKUByqq0NGr9E6htFmxijgI1Es2U="
    ];
  };
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=release-24.11";
    unstable.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    snowfall-drift = {
      url = "github:snowfallorg/drift";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    crane.url = "github:ipetkov/crane";
  };
  outputs = inputs: let
    supportedSystems = [
      "x86_64-linux"
    ];
  in
    inputs.snowfall-lib.mkFlake {
      inherit inputs supportedSystems;
      src = ./.;

      overlays = with inputs; [
        snowfall-drift.overlays.default
        fenix.overlays.default
      ];

      outputs-builder = channels: {
        formatter = channels.nixpkgs.alejandra;
      };
    };
}
