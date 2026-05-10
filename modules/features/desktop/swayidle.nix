# modules/features/desktop/swayidle.nix
#
# Idle management: auto-lock, auto-suspend, lock-before-sleep.
# Respects systemd inhibitor locks (e.g., video playback in Firefox/mpv).
{ config, pkgs, ... }:
let
  dms = config.programs.dank-material-shell;
in
{
  home.packages = [ pkgs.swayidle ];

  # swayidle user service — starts automatically with the Wayland session.
  #
  # Timeout chain:
  #   5 min idle  → lock screen (via DMS IPC)
  #
  # Hooks:
  #   before-sleep → lock screen (covers lid-close, manual suspend, etc.)
  #
  # No after-resume hook: DMS manages its own lock screen via
  # loginctlLockIntegration. After resume, DMS's lock screen (triggered
  # by before-sleep) remains showing until the user authenticates.
  # Calling `loginctl unlock-sessions` on resume would send an
  # UnlockSession signal that DMS would interpret as "dismiss the lock
  # screen" — the opposite of what we want. It also fails without
  # polkit authorization (org.freedesktop.login1.lock-sessions requires
  # auth_admin_keep).
  #
  # Media awareness:
  #   swayidle automatically checks for systemd inhibitor locks.
  #   When Firefox/mpv/etc. plays video, they hold a "delay" inhibitor
  #   that prevents swayidle from triggering timeouts.
  systemd.user.services.swayidle = {
    Unit = {
      Description = "Idle management daemon (auto-lock + auto-suspend)";
      PartOf = [ "graphical-session.target" ];
      BindsTo = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = ''
        ${pkgs.swayidle}/bin/swayidle -w \
          timeout 300 '${dms.package}/bin/dms ipc call lock lock' \
          before-sleep '${dms.package}/bin/dms ipc call lock lock'
      '';
      Restart = "on-failure";
      RestartSec = "5";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
