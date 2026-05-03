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
  #  10 min idle  → suspend to RAM
  #
  # Hooks:
  #   before-sleep → lock screen (covers lid-close, manual suspend, etc.)
  #   after-resume → unlock sessions (so you see the lock screen on wake)
  #
  # Media awareness:
  #   swayidle automatically checks for systemd inhibitor locks.
  #   When Firefox/mpv/etc. plays video, they hold a "delay" inhibitor
  #   that prevents swayidle from triggering timeouts.
  systemd.user.services.swayidle = {
    Unit = {
      Description = "Idle management daemon (auto-lock + auto-suspend)";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = ''
        ${pkgs.swayidle}/bin/swayidle -w \
          timeout 300 '${dms.package}/bin/dms ipc call lock lock' \
          timeout 600 '${pkgs.systemd}/bin/systemctl suspend' \
          before-sleep '${dms.package}/bin/dms ipc call lock lock' \
          after-resume '${pkgs.systemd}/bin/loginctl unlock-sessions'
      '';
      Restart = "on-failure";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
