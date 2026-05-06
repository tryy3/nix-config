# modules/features/desktop/home.nix
#
# Home Manager desktop configuration.
{ pkgs, ... }:
{
  imports = [
    ./gtk.nix
    ./playerctl.nix
    ./dms.nix
    ./swayidle.nix
  ];

  home.packages = [
    pkgs.pavucontrol
    pkgs.galculator
  ];
}
