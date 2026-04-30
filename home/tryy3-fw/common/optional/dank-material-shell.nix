# Home-manager configuration for DankMaterialShell.
# Pair with hosts/common/optional/dank-material-shell.nix for system-level services.
#
# Reference:
#   https://danklinux.com/docs/dankmaterialshell
{ inputs, pkgs, ... }:
{
  imports = [
    inputs.dms.homeModules.dank-material-shell
  ];

  programs.dank-material-shell = {
    enable = true;
    dgop.package = pkgs.unstable.dgop;

    # Auto-start dms via systemd user service (binds to wayland session target).
    systemd.enable = true;

    # FIXME: customize as desired. Settings are merged into
    # ~/.config/DankMaterialShell/settings.json.
    # settings = { };
    # session = { };
    # clipboardSettings = { };
  };
}
