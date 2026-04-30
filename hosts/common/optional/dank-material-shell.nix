# System-level enablement of DankMaterialShell.
# Adds polkit, power-profiles-daemon, accounts-daemon, geoclue2, and the
# dms/quickshell packages system-wide. Pair with the home-manager module at
# home/<user>/common/optional/dank-material-shell.nix for user-side configuration.
#
# NOTE: DMS targets nixpkgs-unstable upstream. We do NOT override its
# `inputs.nixpkgs.follows`, so the module uses the consumer pkgs (this repo's
# 25.11) for dms-shell and quickshell. If a build fails on stable, switch to
# the `unstable` overlay (see overlays/default.nix).
{ inputs, ... }:
{
  imports = [
    inputs.dms.nixosModules.dank-material-shell
  ];

  programs.dank-material-shell.enable = true;
  programs.dang-material-shell = {
    enable = true;
    systemd.enable = true;
    dgop.package = pkgs.unstable.dgop;

    # settings = { };
    # session = { };
    # clipboardSettings = { };
  };
}
