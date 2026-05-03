# modules/features/desktop/home.nix
#
# Home Manager desktop configuration.
{ pkgs, ... }:
{
  imports = [
    ./gtk.nix
    ./playerctl.nix
    ./mango.nix
    ./dms.nix
  ];

  home.packages = [
    pkgs.pavucontrol
    pkgs.galculator
  ];
}
