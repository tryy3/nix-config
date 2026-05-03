{ pkgs, ... }:
let
  spotifyWeb = pkgs.writeShellScriptBin "spotify-web" ''
    set -euo pipefail
    DATA_DIR="''${XDG_DATA_HOME:-$HOME/.local/share}/web-apps/spotify"
    mkdir -p "$DATA_DIR"
    exec ${pkgs.brave}/bin/brave \
      --app=https://open.spotify.com \
      --user-data-dir="$DATA_DIR" \
      --class=spotify-web \
      --name=spotify-web \
      --enable-features=UseOzonePlatform \
      --ozone-platform=wayland \
      "$@"
  '';
in
{
  home.packages = [
    pkgs.brave
    spotifyWeb
  ];

  xdg.desktopEntries.spotify-web = {
    name = "Spotify";
    genericName = "Music Player";
    exec = "spotify-web %U";
    terminal = false;
    type = "Application";
    categories = [
      "AudioVideo"
      "Audio"
      "Player"
    ];
    startupNotify = true;
  };
}
