# modules/features/kicad/default.nix
#
# KiCad feature: Open Source Electronics Design Automation suite.
{config, ...}: let
  username = config.hostSpec.username;
in {
  home-manager.users.${username}.imports = [./home.nix];
}
