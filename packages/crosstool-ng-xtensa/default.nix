{
  lib,
  inputs,
  namespace,
  pkgs,
  stdenv,
  writeShellScriptBin,
  fetchFromGitHub,
  ...
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "crosstool-ng-xtensa";
  version = "esp-14.2.0_20241119";

  src = fetchFromGitHub {
    owner = "espressif";
    repo = "crosstool-ng";
    sha256 = "hRTq5AMODVlRygriGymQQ547KnK5yW4tqxqttaE19S8=";
    rev = "refs/tags/${finalAttrs.version}";
    leaveDotGit = true;
  };

  nativeBuildInputs = with pkgs; [
    autoconf
    automake
    coreutils
    curl
    gcc
    git
    python3
  ];

  buildInputs = with pkgs; [
    aria
    bison
    cvs
    file
    flex
    gperf
    help2man
    libtool
    ncurses
    texinfo
    unzip
    wget
    which
  ];

  configurePhase = ''
    ./bootstrap
    ./configure --disable-static --enable-local --prefix=/usr
  '';

  buildPhase = ''
    make
  '';

  installPhase = ''
    make DESTDIR=$out install
  '';

  passthru.update = let
    inherit (lib) getExe;
    curl = getExe pkgs.curl;
    jq = getExe pkgs.jq;
  in
    writeShellScriptBin "update-my-package" ''
      set -euo pipefail

      latest="$(${curl} -s "https://api.github.com/repos/${finalAttrs.src.owner}/${finalAttrs.src.repo}/releases?per_page=1" | ${jq} -r ".[0].tag_name")"

      drift rewrite --auto-hash --new-version "$latest"
    '';

  meta.mainProgram = "ct-ng";
})
