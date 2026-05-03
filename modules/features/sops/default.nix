# modules/features/sops/default.nix
#
# Sops feature: Home Manager sops-nix integration.
{ config, ... }:
let
  username = config.hostSpec.username;
in
{
  home-manager.users.${username}.imports = [ ./home.nix ];
}
