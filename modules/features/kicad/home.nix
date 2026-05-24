# modules/features/kicad/home.nix
#
# Home Manager configuration for KiCad.
{pkgs, ...}: {
  home.packages = [pkgs.unstable.kicad];
}
