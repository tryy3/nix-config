# modules/features/fonts/default.nix
#
# Fonts feature: installs font packages system-wide.
{ pkgs, ... }:
{
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
  ];
}
