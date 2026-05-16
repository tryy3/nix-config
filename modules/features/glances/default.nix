# modules/features/glances/default.nix
#
# Glances feature: system resource monitor.
{config, ...}: let
  username = config.hostSpec.username;
in {
  home-manager.users.${username}.imports = [./home.nix];
}
