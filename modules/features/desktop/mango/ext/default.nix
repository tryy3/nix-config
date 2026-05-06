# modules/features/desktop/mango/ext/default.nix
#
# NixOS-level configuration for the mango-ext compositor (ernestoCruz05 fork).
# Import this module in your host declaration to use the extended mango build
# with canvas, dwindle layout, and touch features.
#
# Usage in modules/hosts/<hostname>.nix:
#   imports = [ ../features/desktop/mango/ext ];
#
# To switch back to stable, replace this import with:
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
  imports = [ inputs.mango-ext.nixosModules.mango ];

  programs.mango.enable = true;

  home-manager.users.${username}.imports = [ ./home.nix ];
}
