# This file defines the configuration of [`treefmt-nix`](https://github.com/numtide/treefmt-nix).
# It is referenced in [`02_main.nix`](./02_main.nix) both for formatting and checking formatting.
# You can format the project with `nix fmt`.

{ pkgs, ... }:
{
  projectRootFile = "flake.nix"; # used to find the project root
  programs.nixfmt.enable = true;
  programs.prettier = {
    enable = true;
    includes = [
      "*.md"
      "*.mdx"
      "*.yaml"
      "*.yml"
      # The following file types might also be formatted with `prettier` altough
      # they currently do not occur in this project.
      "*.css"
      "*.html"
      "*.js"
      "*.json"
      "*.json5"
    ];
    excludes = [
      # `/supply-chain/` holds the configuration of [`cargo-vet`](https://github.com/mozilla/cargo-vet).
      # `cargo-vet` has its own behavior when it comes to formatting and those files are generally
      # machine-(re-)generated. Thus, they should not be formatted again by `nix fmt`.
      "supply-chain/*"
    ];
  };
  programs.taplo = {
    enable = true;
    includes = [
      # Taplo does not support TOML 1.1 buty only TOML 1.0. Still, Taplo seems to be a solid decision today
      # and we do not have any TOML files using the new TOML 1.1 features.
      "*.toml"
    ];
  };
  programs.rustfmt = {
    enable = true;
    includes = [
      "*.rs"
    ];
  };
}
