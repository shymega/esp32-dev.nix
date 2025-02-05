{
  lib,
  inputs,
  namespace,
  pkgs,
  stdenv,
  fetchurl,
  fetchzip,
  writeShellScriptBin,
  autoPatchelfHook,
  libusb1,
  zlib,
  buildFHSUserEnv,
}: let
  name = "openocd-esp32";
  owner = "espressif";
  version = "0.11.0-esp32-20220706";
  hash = "sha256-2t9+XRU3BT2QUSGqUBKjvozIHruFk0RTxIwRs9dPbG4=";
  arch = "amd64";
in
  stdenv.mkDerivation rec {
    inherit name version;

    src = fetchzip {
      url = "https://github.com/${owner}/${name}/releases/download/v${version}/${name}-linux-${arch}-${version}.tar.gz";
      inherit hash;
    };

    buildInputs = [
      zlib
      libusb1
    ];
    nativeBuildInputs = [autoPatchelfHook];

    phases = ["unpackPhase" "installPhase"];

    installPhase = ''
      cp -r . $out
      autoPatchelf $out/bin/openocd
    '';

    passthru.update = writeShellScriptBin "update-my-package" ''
      set -euo pipefail

      latest="$(${pkgs.curl}/bin/curl -s "https://api.github.com/repos/${src.owner}/${src.repo}/releases?per_page=1" | ${pkgs.jq}/bin/jq -r ".[0].tag_name" | ${pkgs.gnused}/bin/sed 's/^v//')"

      drift rewrite --auto-hash --new-version "$latest"
    '';

    meta = with lib; {
      description = "ESP32 toolchain";
      homepage = https://docs.espressif.com/projects/esp-idf/en/stable/get-started/linux-setup.html;
      mainProgram = "openocd";
      license = licenses.gpl3;
    };
  }
