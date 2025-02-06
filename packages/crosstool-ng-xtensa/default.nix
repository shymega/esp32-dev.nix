{
  lib,
  inputs,
  namespace,
  pkgs,
  stdenv,
  writeShellScriptBin,
  fetchFromGitHub,
}:
with pkgs; let
  owner = "espressif";
  repo = "crosstool-ng";
  pname = "crosstool-ng-xtensa";
  version = "esp-14.2.0_20241119";
  sha256 = "sha256-hRTq5AMODVlRygriGymQQ547KnK5yW4tqxqttaE19S8=";
in
  stdenv.mkDerivation rec {
    inherit pname version;

    src = fetchFromGitHub {
      inherit owner repo sha256;
      rev = "refs/tags/${version}";
      leaveDotGit = true;
    };

    nativeBuildInputs = [
      autoconf
      automake
      binutils
      bison
      flex
      gettext
      git
      gperf
      help2man
      libtool
      ncurses
      texinfo
      which
      wget
      unzip
    ];

    preConfigure = "bash ./bootstrap";

    passthru.update = let
      inherit (lib) getExe;
      curl = getExe pkgs.curl;
      jq = getExe pkgs.jq;
    in writeShellScriptBin "update-my-package" ''
      set -euo pipefail

      latest="$(${curl} -s "https://api.github.com/repos/${owner}/${repo}/releases?per_page=1" | ${jq} -r ".[0].tag_name")"

      drift rewrite --auto-hash --new-version "$latest"
    '';

    meta.mainProgram = "ct-ng";
  }
