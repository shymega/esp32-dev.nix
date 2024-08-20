{ lib
, prev
, stdenv
, fetchurl
}:
let
  platform = {
    x86_64-linux = "x86_64-unknown-linux-gnu";
    aarch64-linux = "aarch64-unknown-linux-gnu";
    x86_64-darwin = "x86_64-apple-darwin";
    aarch64-darwin = "aarch64-apple-darwin";
  }.${stdenv.hostPlatform.system} or (throw "unsupported system ${stdenv.hostPlatform.system}");
  rpath = "${prev.zlib}/lib:${prev.libxml2}/lib:${prev.stdenv.cc.cc.lib}/lib:$out/lib";
in
stdenv.mkDerivation rec {
  pname = "rust-esp";
  version = "1.79.0.0";

  src = fetchurl {
    url = "https://github.com/esp-rs/rust-build/releases/download/v${version}/rust-${version}-${platform}.tar.xz";
    sha256 = {
      aarch64-linux = lib.fakeSha256;
      x86_64-linux = "sha256-xfxl2OZSTi+zizE2aabV2+eUWhrMS4vsgn3kQEANyfc=";
      x86_64-darwin = lib.fakeSha256;
      aarch64-darwin = "sha256-iWnzDk2wXh0DH6o/a2vEjQgebC8Dkoqo2H0Vsoxwupw=";
    }.${stdenv.hostPlatform.system};
  };

  installPhase = ''
    patchShebangs install.sh
    CFG_DISABLE_LDCONFIG=1 ./install.sh --prefix=$out

    rm $out/lib/rustlib/{components,install.log,manifest-*,rust-installer-version,uninstall.sh} || true

    ${lib.optionalString stdenv.isLinux ''
      if [ -d $out/bin ]; then
        for file in $(find $out/bin -type f); do
          if isELF "$file"; then
            patchelf \
              --set-interpreter ${stdenv.cc.bintools.dynamicLinker} \
              --set-rpath ${rpath} \
              "$file" || true
          fi
        done
      fi

      if [ -d $out/lib ]; then
        for file in $(find $out/lib -type f); do
          if isELF "$file"; then
            patchelf --set-rpath ${rpath} "$file" || true
          fi
        done
      fi

      if [ -d $out/libexec ]; then
        for file in $(find $out/libexec -type f); do
          if isELF "$file"; then
            patchelf \
              --set-interpreter ${stdenv.cc.bintools.dynamicLinker} \
              --set-rpath ${rpath} \
              "$file" || true
          fi
        done
      fi

      for file in $(find $out/lib/rustlib/*/bin -type f); do
        if isELF "$file"; then
          patchelf \
            --set-interpreter ${stdenv.cc.bintools.dynamicLinker} \
            --set-rpath ${stdenv.cc.cc.lib}/lib:${rpath} \
            "$file" || true
        fi
      done
    ''}
  '';
  dontStrip = true;
}
