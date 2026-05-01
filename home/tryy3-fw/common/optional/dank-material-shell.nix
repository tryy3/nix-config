# Home-manager configuration for DankMaterialShell.
# Pair with hosts/common/optional/dank-material-shell.nix for system-level services.
#
# Reference:
#   https://danklinux.com/docs/dankmaterialshell
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.dank-material-shell;
in
{
  imports = [
    inputs.dms.homeModules.dank-material-shell
  ];

  programs.dank-material-shell = {
    enable = true;
    enableSystemMonitoring = true;
    dgop.package = inputs.dgop.packages.${pkgs.system}.default;
    # quickshell.package = pkgs.unstable.quickshell;

    # Auto-start dms via systemd user service (binds to wayland session target).
    systemd.enable = true;

    # FIXME: customize as desired. Settings are merged into
    # ~/.config/DankMaterialShell/settings.json.
    # settings = { };
    # session = { };
    # clipboardSettings = { };
  };

  # The DMS Go binary spawns `qs` (quickshell), and the QML config in turn
  # spawns lots of helpers (matugen, wtype, sh, grep, touch, dms itself, etc.).
  # The user systemd manager's PATH is essentially empty (only contains
  # systemd's own bin dir), so we must provide a full PATH for the unit.
  #
  # We include the standard NixOS user-profile locations so anything installed
  # via home.packages, environment.systemPackages, or the default Nix profile
  # is reachable.
  systemd.user.services.dms.Service.Environment = [
    "PATH=${
      lib.makeBinPath [
        cfg.quickshell.package
        cfg.package
      ]
    }:${config.home.profileDirectory}/bin:/etc/profiles/per-user/${config.home.username}/bin:/run/current-system/sw/bin:/run/wrappers/bin"
  ];
}
