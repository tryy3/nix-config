# modules/features/browsers/home.nix
#
# Home Manager browser configuration.
{ ... }:
{
  imports = [
    ./chromium.nix
    ./firefox.nix
    ./vesktop.nix
    ./web-apps.nix
    ./zen.nix
  ];
}
