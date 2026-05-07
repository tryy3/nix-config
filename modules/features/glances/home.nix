# modules/features/glances/home.nix
#
# Home Manager configuration for Glances.
{ pkgs, ... }:
{
  home.packages = [ pkgs.glances ];
}
