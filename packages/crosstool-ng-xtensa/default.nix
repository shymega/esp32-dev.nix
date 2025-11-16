{
  lib,
  inputs,
  namespace,
  pkgs,
  nix-update-script,
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
    tag = finalAttrs.version;
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

  passthru.updateScript = nix-update-script {};

  meta.mainProgram = "ct-ng";
})
