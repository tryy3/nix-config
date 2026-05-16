# modules/features/lm-studio/home.nix
#
# Home Manager configuration for LM Studio.
{pkgs, ...}: {
  home.packages = [pkgs.unstable.lmstudio];
}
