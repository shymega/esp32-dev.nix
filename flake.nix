{
  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    crane.url = "github:ipetkov/crane";
  };
  outputs = { self, ... }@inputs:
    inputs.flake-utils.lib.eachSystem [ "x86_64-linux" ]
      (system:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ inputs.fenix.overlays.default ];
            config = {
              allowBroken = true;
            };
          };
          inherit (pkgs.stdenv) mkDerivation;
          inherit (pkgs) fetchzip;

          rust-esp-version = "1.80.0.0";

          rust-esp-toolchain-src = fetchzip {
            url = "https://github.com/esp-rs/rust-build/releases/download/v${rust-esp-version}/rust-src-${rust-esp-version}.tar.xz";
            sha256 = "sha256-mnPUNyB1w1lqrSfpcnZi5OO/l84CuuidbP6TEMKMBV8=";
          };

          rust-esp-toolchain-bin = fetchzip {
            url = "https://github.com/esp-rs/rust-build/releases/download/v${rust-esp-version}/rust-${rust-esp-version}-x86_64-unknown-linux-gnu.tar.xz";
            sha256 = "sha256-y07tXCTlzAN22O950U89jiBFsou+K9DiiIy5oCYqlV8=";
          };

          esp-toolchain = mkDerivation {
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


          xtensa-esp32-elf-clang = mkDerivation {
            name = "xtensa-esp32-elf-clang";

            src = fetchzip {
              url = "https://github.com/espressif/llvm-project/releases/download/esp-16.0.0-20230516/libs_llvm-esp-16.0.0-20230516-linux-amd64.tar.xz";
              sha256 = "sha256-T9MBRQZ5fI+x3SuDL1ngd0ksq+VdZ5DMnE6VROxu85c=";
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
