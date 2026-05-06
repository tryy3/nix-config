# modules/features/desktop/mango/stable/default.nix
#
# NixOS-level configuration for the stable (upstream) MangoWC compositor.
# Import this module in your host declaration to use the upstream mango build.
#
# Usage in modules/hosts/<hostname>.nix:
#   imports = [ ../features/desktop/mango/stable ];
{
  config,
  inputs,
  ...
}:
let
  username = config.hostSpec.username;
in
{
  imports = [ inputs.mango.nixosModules.mango ];

  programs.mango.enable = true;

  home-manager.users.${username}.imports = [ ./home.nix ];
}
