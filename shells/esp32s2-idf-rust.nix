{ pkgs ? import ../default.nix }:
pkgs.mkShell {
  name = "esp-idf";

  buildInputs = with pkgs; [
    gcc-xtensa-esp32s2-elf-bin
    openocd-esp32-bin
    # esp-idf
    # esptool

    # Tools required to use ESP-IDF.
    git
    wget
    gnumake

    flex
    bison
    gperf
    pkg-config

    cmake
    ninja

    ncurses5

    llvm-xtensa
    rust-esp

    # pythonEnv.python
    # (python3.withPackages (p: with p; [pip]))
    python3
    python3Packages.pip
    python3Packages.virtualenv
    # stdenv.cc.cc.lib
    # zlib
    # libxml2
  ];
  shellHook = ''
    # fixes libstdc++ issues and libgl.so issues
    # export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${pkgs.stdenv.cc.cc.lib}/lib/:${pkgs.zlib}/lib:${pkgs.pkgsi686Linux.libxml2.dev}/lib
    export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath [ pkgs.libxml2 pkgs.zlib pkgs.stdenv.cc.cc.lib ]}
    export ESP_IDF_VERSION=v4.4.1
    # export LIBCLANG_PATH=${pkgs.llvmPackages.libclang.lib}/lib
    export LIBCLANG_PATH=${pkgs.llvm-xtensa}/lib
  '';
}
