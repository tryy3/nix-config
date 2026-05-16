# modules/features/steam/home.nix
#
# Home Manager configuration for Steam / gaming utilities.
{pkgs, ...}: {
  home.packages = with pkgs; [
    gamescope # Steam compositor for micro-compositing
    mangohud # In-game overlay (FPS, frametime, GPU load)
  ];
}
