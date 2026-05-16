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
  pkgs,
  ...
}:
let
  username = config.hostSpec.username;
in
{
  imports = [
    inputs.mango.nixosModules.mango
    inputs.mango-ext.nixosModules.mango-ext
  ];

  programs.mango = {
    enable = false;
    package = pkgs.runCommand "mango-greeter-shim" { } ''
      mkdir -p $out/bin
      ln -s ${config.programs.mango-ext.package}/bin/mango-ext $out/bin/mango
    '';
  };
  programs.mango-ext.enable = true;

  home-manager.users.${username}.imports = [ ./home.nix ];
}
