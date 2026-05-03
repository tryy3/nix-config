# modules/features/git/default.nix
#
# Git feature: version control with git.
{ config, ... }:
let
  username = config.hostSpec.username;
in
{
  programs.git.enable = true;
  home-manager.users.${username}.imports = [ ./home.nix ];
}
