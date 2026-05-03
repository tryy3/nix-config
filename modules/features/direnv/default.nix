# modules/features/direnv/default.nix
#
# Direnv feature: automatic environment switching.
{ config, ... }:
let
  username = config.hostSpec.username;
in
{
  home-manager.users.${username}.imports = [ ./home.nix ];
}
