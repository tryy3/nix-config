# modules/features/obsidian/home.nix
#
# Obsidian HM config: installs the app and provides a desktop entry.
{ pkgs, ... }:
{
  home.packages = [ pkgs.unstable.obsidian ];
}
