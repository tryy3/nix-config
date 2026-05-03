# modules/features/kubernetes/default.nix
#
# Kubernetes feature: kubectl, talosctl, omnictl.
{ config, ... }:
let
  username = config.hostSpec.username;
in
{
  home-manager.users.${username}.imports = [ ./home.nix ];
}
