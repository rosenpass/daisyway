{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };


  outputs = (inputs:
    let scoped = (scope: scope.result);
    in scoped rec {
      inherit (builtins) removeAttrs;

      result = (import ./nix/01_init.nix) {
        scoped = scoped;
        flake.self = inputs.self;
        flake.inputs = removeAttrs inputs ["self"];
      };
    }
  );
}
