# modules/features/ssh/default.nix
#
# SSH feature: SSH client configuration.
{ config, ... }:
let
  username = config.hostSpec.username;
in
{
  home-manager.users.${username}.imports = [ ./home.nix ];
}
