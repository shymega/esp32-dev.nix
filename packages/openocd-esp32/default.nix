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
  version = "0.12.0-esp32-20241016";
  sha256 = "sroUQw8yfAidKPk0oCoprEGqMnCJZwHrrvH9pAOITTI=";
  arch = "amd64";
in
  stdenv.mkDerivation rec {
    inherit name version;

    src = fetchzip {
      url = "https://github.com/${owner}/${name}/releases/download/v${version}/${name}-linux-${arch}-${version}.tar.gz";
      inherit sha256;
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

    passthru.update = let
      inherit (lib) getExe;
      curl = getExe pkgs.curl;
      jq = getExe pkgs.jq;
      sed = getExe pkgs.gnused;
    in writeShellScriptBin "update-my-package" ''
      set -euo pipefail

      latest="$(${curl} -s "https://api.github.com/repos/${owner}/${name}/releases?per_page=1" | ${jq} -r ".[0].tag_name" | ${sed} 's/^v//')"

      drift rewrite --auto-hash --new-version "$latest"
    '';

    meta = with lib; {
      description = "ESP32 toolchain";
      homepage = https://docs.espressif.com/projects/esp-idf/en/stable/get-started/linux-setup.html;
      mainProgram = "openocd";
      license = licenses.gpl3;
    };
  }
