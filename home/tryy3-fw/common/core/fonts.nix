{ pkgs, ... }:
{
  fonts.fontconfig.enable = true;
  home.packages = [
    pkgs.noto-fonts
    pkgs.nerd-fonts.jetbrains-mono # used by zed (and a sensible terminal default)
  ];
}
