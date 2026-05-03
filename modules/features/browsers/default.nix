# modules/features/browsers/default.nix
#
# Browsers feature: Firefox, Zen, Chromium, Vesktop, web apps.
{ config, ... }:
let
  username = config.hostSpec.username;
in
{
  home-manager.users.${username}.imports = [ ./home.nix ];
}
