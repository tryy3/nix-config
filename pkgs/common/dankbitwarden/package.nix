{
  lib,
  stdenv,
  fetchFromGitHub,
}:
stdenv.mkDerivation rec {
  pname = "dankbitwarden";
  version = "4cf0dc4dd91bb07c4fbbdb0ec25fd173f4584e5a";

  src = fetchFromGitHub {
    owner = "tryy3";
    repo = "DankBitwarden";
    rev = version;
    hash = "sha256-NZqFWhl2DJafCyaaQisxjwFO1CMuXKCWuBB+pJDMaLg=";
  };

  installPhase = ''
    mkdir -p $out/share/dankbitwarden
    cp DankBitwarden.qml DankBitwardenSettings.qml plugin.json $out/share/dankbitwarden/
  '';

  meta = {
    description = "Bitwarden launcher plugin for DankMaterialShell using rbw";
    homepage = "https://github.com/tryy3/DankBitwarden";
    license = lib.licenses.mit;
    maintainers = [lib.maintainers.tryy3];
  };
}
