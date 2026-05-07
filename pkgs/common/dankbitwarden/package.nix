{
  lib,
  stdenv,
  fetchFromGitHub,
}:

stdenv.mkDerivation rec {
  pname = "dankbitwarden";
  version = "3d70eb342750fe64f2baa8f69102992f2a644d98";

  src = fetchFromGitHub {
    owner = "tryy3";
    repo = "DankBitwarden";
    rev = version;
    hash = "sha256-/O2QXF/0zNbSvkq5SwIyHdozcR39FNLc5CuFfeD3XBc=";
  };

  installPhase = ''
    mkdir -p $out/share/dankbitwarden
    cp DankBitwarden.qml DankBitwardenSettings.qml plugin.json $out/share/dankbitwarden/
  '';

  meta = {
    description = "Bitwarden launcher plugin for DankMaterialShell using rbw";
    homepage = "https://github.com/tryy3/DankBitwarden";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.tryy3 ];
  };
}
