# modules/features/ghostty/default.nix
#
# Ghostty terminal emulator feature.
{ config, ... }:
let
  username = config.hostSpec.username;
in
{
  home-manager.users.${username}.imports = [ ./home.nix ];
}
