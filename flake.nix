{
  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
      # inputs.flake-compat.follows = "flake-compat";
      # inputs.utils.follows = "utils";
    };
  };
  outputs = { self, ... }@inputs:
    inputs.flake-utils.lib.eachSystem [ "x86_64-linux" ]
      (system:
        let
          inherit (builtins) fetchTarball;
          lib = pkgs.lib;
          pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ inputs.fenix.overlays.default ];
            config = {
              allowBroken = true;
            };
          };

          rust-esp-version = "1.80.0.0";

          rust-esp-toolchain-src = fetchTarball {
            url = "https://github.com/esp-rs/rust-build/releases/download/v${rust-esp-version}/rust-src-${rust-esp-version}.tar.xz";
            sha256 = "0pq5ik1114zydjfyifh2rsbvzqz4c9v75s97mmm5khvm40vx8wws";
          };

          rust-esp-toolchain-bin = fetchTarball {
            url = "https://github.com/esp-rs/rust-build/releases/download/v${rust-esp-version}/rust-${rust-esp-version}-x86_64-unknown-linux-gnu.tar.xz";
            sha256 = "0pwm58ka1fcci3id0axyifr4a84f7m7x2yggv1v07k754iffsknb";
          };

          esp-toolchain = pkgs.stdenv.mkDerivation {
            name = "esp-toolchain";

            # Skip src requirement
            unpackPhase = "true";

            buildInputs = [
              rust-esp-toolchain-bin
              rust-esp-toolchain-src

              # make it work on NixOS
              pkgs.autoPatchelfHook
              pkgs.stdenv.cc.cc.lib
              pkgs.zlib
            ];

            installPhase = ''
              mkdir -p $out/
              mkdir -p $out/lib/rustlib

              # somehow otherwise has no permission to copy
              touch $out/lib/rustlib/uninstall.sh

              bash ${rust-esp-toolchain-bin}/install.sh --destdir=$out --prefix="" --without=rust-docs-json-preview,rust-docs --disable-ldconfig
              bash ${rust-esp-toolchain-src}/install.sh --destdir=$out --prefix="" --disable-ldconfig
            '';
          };


          xtensa-esp32-elf-clang = pkgs.stdenv.mkDerivation {
            name = "xtensa-esp32-elf-clang";

            src = fetchTarball {
              url = "https://github.com/espressif/llvm-project/releases/download/esp-16.0.0-20230516/libs_llvm-esp-16.0.0-20230516-linux-amd64.tar.xz";
              sha256 = "15zkdvn495afkk690rsxwnmjqjbpw1cjz0rbvnqqyz3r0r2h3lsg";
            };

            buildInputs = [
              # make it work on NixOS
              pkgs.autoPatchelfHook
              pkgs.stdenv.cc.cc.lib
              pkgs.zlib
              pkgs.libxml2
            ];

            installPhase = ''
              cp -R $src $out
            '';
          };

        in
        rec {
          packages = {
            inherit esp-toolchain xtensa-esp32-elf-clang;
            allPackages = packages.esp-toolchain // packages.xtensa-esp32-elf-clang;
          };
        }) // {
      overlays.default = final: prev: {
        inherit (self.packages.${final.system}) esp-toolchain xtensa-esp32-elf-clang;
      };
    };
}
