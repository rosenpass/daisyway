# Changelog

## v0.1.1 (2026-10-15)

### Fixes

- upgrade Cargo dependencies (resolves RUSTSEC-2026-0347)
- throw out custom version of `log::LevelFilter`
- include contents of `REAMDE.md` in the Rust binary and library documentation (they did not have any documentation before)

### Other

- increase MSRV from 1.88.0 to 1.89.0
- add formatter to Nix flake (`nix fmt` command can now be used)
- remove `simulator` from Nix devshell (unnecessary and very compute-expensive entry; just call it like `cargo run --bin simulator`)
- somewhat unify the two Rust packages' settings (`daisyway` and `simulator`) by moving them to the workspace's `Cargo.toml`
- CI now runs on Ubicloud
- improve CI performance (runs faster now)
- add badges to `README.md`
- slightly reword the `Development` section in the `README.md`

## older versions

TODO: document older versions
