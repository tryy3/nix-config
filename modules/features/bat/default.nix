# modules/features/bat/default.nix
#
# Bat feature: cat replacement with syntax highlighting.
{ config, ... }:
let
  username = config.hostSpec.username;
in
{
  home-manager.users.${username}.imports = [ ./home.nix ];
}
