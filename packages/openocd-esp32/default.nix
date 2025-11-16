{ nix-update-script, zlib, autoreconfHook, openocd, fetchFromGitHub, ... }:
openocd.overrideAttrs (finalAttrs: prevAttrs: {
  version = "0.12.0-esp32-20250707";
  src = fetchFromGitHub {
    repo = "openocd-esp32";
    owner = "espressif";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Tg/8Je+ixp4XL+y7ZLtMQ7U6umjUBqdPlXTuWLx54P4=";
  };

  nativeBuildInputs = (prevAttrs.nativeBuildInputs or []) ++ [
    autoreconfHook
  ];

  buildInputs = (prevAttrs.buildInputs or []) ++ [
    zlib
  ];

  passthru.updateScript = nix-update-script {};
})
