ctx:
ctx.scoped rec {
  inherit (builtins) fromTOML readFile trace;

  inherit (ctx.flake.inputs) nixpkgs;
  inherit (nixpkgs.lib.fileset) toSource;
  inherit (nixpkgs.lib.sources) sourceByRegex cleanSourceWith;
  inherit (ctx.flake.inputs) treefmt-nix;
  inherit (ctx) flake;

  # TODO: This is really ugly – use flake-parts?
  pkgs =
    ctx.flake.inputs.nixpkgs.legacyPackages.${ctx.system.name}.extend
      ctx.flake.inputs.rust-overlay.overlays.default;

  inherit (pkgs) mkShell;
  inherit (pkgs.testers) runNixOSTest;
  inherit (pkgs.stdenv) mkDerivation;
  inherit (pkgs.writers) writePython3Bin;

  # TODO: The overlay is now working as it should
  inherit
    (pkgs.makeRustPlatform {
      cargo = packages.daisywayToolchain;
      rustc = packages.daisywayToolchain;
    })
    buildRustPackage
    ;

  git = {
    revision = ctx.flake.self.rev or ctx.flake.self.dirtyRev;
  };

  result.packages = packages // checks;
  result.devShells = devShells;
  result.apps = apps;
  result.checks = checks;
  result.formatter = formatter;

  apps = { };

  # TODO: Path should be a config variable
  workspace.path = ../.;
  workspace.toml = readToml (workspace.path + "/Cargo.toml");
  workspace.src = sourceByRegex workspace.path [
    "^Cargo.(lock|toml)$"
    "^README\.md$"
    "^daisyway$"
    "^daisyway/Cargo\.(toml)$"
    "^daisyway/build.rs$"
    "^daisyway/src/?.*$"
    "^simulator$"
    "^simulator/Cargo\.(toml)$"
    "^simulator/src/?.*$"
  ];

  toml = readToml (workspace.path + "/daisyway/Cargo.toml");

  packages.default = packages.daisyway;

  # TODO: This is out of sync with the main package
  packages.daisywayToolchain = pkgs.rust-bin.fromRustupToolchainFile (
    workspace.path + "/rust-toolchain.toml"
  );

  packages.daisyway = buildRustPackage {
    name = toml.package.name;
    version = toml.package.version;
    src = workspace.src;
    doCheck = true;
    cargoLock.lockFile = workspace.path + "/Cargo.lock";
    buildAndTestSubdir = "daisyway";
    meta.description = toml.package.description;
    meta.homepage = toml.package.description;
    meta.license = with pkgs.lib.licenses; [
      mit
      asl20
    ];
    meta.platforms = pkgs.lib.platforms.all;
  };

  packages.daisywayQkdSimulator = buildRustPackage {
    name = "daisywayQkdSimulator";
    version = toml.package.version;
    src = workspace.src;
    doCheck = true;
    cargoLock.lockFile = workspace.path + "/Cargo.lock";
    buildAndTestSubdir = "simulator";
    meta.description = toml.package.description;
    meta.homepage = toml.package.description;
    meta.license = with pkgs.lib.licenses; [
      mit
      asl20
    ];
    meta.platforms = pkgs.lib.platforms.all;
  };

  packages.daisyway-tar = (
    pkgs.runCommand
      "${toml.package.name}-${toml.package.version}-dev-${git.revision}-${pkgs.system}.tar.zst"
      { }
      ''
        ${pkgs.gnutar}/bin/tar -C ${packages.daisyway} -c ${packages.daisyway}/* | ${pkgs.zstd}/bin/zstd > $out
      ''
  );

  packages.daisyway-deb = (
    pkgs.runCommand
      "${toml.package.name}-${toml.package.version}-dev-${git.revision}-${pkgs.system}.deb"
      { }
      ''
        mkdir -p packageroot/DEBIAN

        cat << EOF > packageroot/DEBIAN/control
        Package: ${toml.package.name}
        Version: ${toml.package.version}-dev-${git.revision}
        Architecture: all
        Maintainer: Karolin Varner <karo@rosenpass.eu>
        Depends:
        Description: ${toml.package.description}
        EOF


        mkdir -p packageroot/usr
        cp -Ra ${packages.daisyway}/* packageroot/usr
        ${pkgs.dpkg}/bin/dpkg --build packageroot $out
      ''
  );

  devShells.default = mkShell {
    packages = [
      # Rust toolchain as pinned in rust-toolchain.toml
      # This includes cargo, rustc, cargo-clippy and rustfmt
      packages.daisywayToolchain

      # install the tool from `/simulator/Cargo.toml` by compiling it from source:
      packages.daisywayQkdSimulator

      # various useful packages from nixpkgs:
      pkgs.cargo-audit
      pkgs.cargo-deny
      pkgs.cargo-msrv
      pkgs.cargo-release
      pkgs.cargo-vet
      pkgs.rust-analyzer
      pkgs.rustfmt
      pkgs.prettier
    ];
  };
  # minimal devShell for running cargo-vet efficiently
  # (the default devShell is expensive to install)
  devShells.cargo-vet = mkShell {
    packages = [
      pkgs.cargo
      pkgs.cargo-vet
    ];
  };
  # minimal devShell for running cargo-clippy efficiently
  # (the default devShell is expensive to install)
  devShells.cargo-clippy = mkShell {
    packages = [
      # Rust toolchain as pinned in rust-toolchain.toml
      # This includes cargo, rustc, cargo-clippy and rustfmt
      packages.daisywayToolchain
    ];
  };

  testContext = ctx // {
    system = ctx.system // {
      # TODO: needs better structure
      inherit
        packages
        devShells
        apps
        pkgs
        ;
    };
  };

  checks.integrationTestWireguardConnection = runNixOSTest (
    (import ../tests/integration/wireguard_connection/test.nix) testContext
  );
  checks.formatting = (treefmt-nix.lib.evalModule pkgs ./treefmt.nix).config.build.check flake.self;

  formatter = (treefmt-nix.lib.evalModule pkgs ./treefmt.nix).config.build.wrapper;

  readToml = (file: fromTOML (readFile file));
}
