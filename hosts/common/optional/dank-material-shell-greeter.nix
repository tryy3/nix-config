# DankMaterialShell-based greetd greeter (login screen).
# Enables greetd with the DMS Quickshell-based greeter UI running inside
# a mango compositor session.
#
# Pair with hosts/common/optional/mango.nix and
# hosts/common/optional/dank-material-shell.nix.
#
# Reference:
#   https://github.com/AvengeMedia/DankMaterialShell/blob/master/distro/nix/greeter.nix
{ inputs, config, ... }:
{
  imports = [
    inputs.dms.nixosModules.greeter
  ];

  programs.dank-material-shell.greeter = {
    enable = true;
    compositor.name = "mango";
    # Copy this user's DMS theme/wallpaper/session into the greeter cache
    # so the login screen visually matches the desktop.
    configHome = config.hostSpec.home;
  };
}
