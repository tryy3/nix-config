# modules/features/desktop/battery-notify.nix
#
# Battery level notifications — alerts at 20%, 15%, 10%, and 5% when on battery.
# Also notifies when AC power is plugged in or unplugged.
#
# Integrates with your notification daemon (DMS implements the freedesktop spec,
# so notify-send works out of the box).
{pkgs, ...}: let
  batteryNotifyScript = pkgs.writeShellScript "battery-notify" ''
    #!/usr/bin/env bash
    set -euo pipefail

    NOTIFY_SEND="${pkgs.libnotify}/bin/notify-send"
    INTERVAL=30

    # Track which thresholds have already fired (to avoid repeated notifications)
    declare -A FIRED
    PREV_AC_STATE=""

    # Find the battery sysfs path
    find_battery() {
      for path in /sys/class/power_supply/BAT*; do
        if [[ -f "$path/capacity" && -f "$path/status" ]]; then
          echo "$path"
          return 0
        fi
      done
      return 1
    }

    BATTERY_PATH=$(find_battery) || exit 0  # No battery → exit silently (desktop/VM)

    while true; do
      # Read current state
      CAPACITY=$(cat "$BATTERY_PATH/capacity")
      STATUS=$(cat "$BATTERY_PATH/status")  # "Charging", "Discharging", "Full", "Not charging"
      IS_ON_AC="false"
      [[ "$STATUS" == "Charging" || "$STATUS" == "Full" || "$STATUS" == "Not charging" ]] && IS_ON_AC="true"

      # Detect AC plug/unplug events
      if [[ -n "$PREV_AC_STATE" && "$IS_ON_AC" != "$PREV_AC_STATE" ]]; then
        if [[ "$IS_ON_AC" == "true" ]]; then
          $NOTIFY_SEND --urgency=low --icon="battery-full" \
            "Power Connected" "AC adapter plugged in — charging at ''${CAPACITY}%"
          # Reset fired thresholds when plugged in
          FIRED=()
        else
          $NOTIFY_SEND --urgency=low --icon="battery-caution" \
            "On Battery" "AC adapter unplugged — ''${CAPACITY}% remaining"
        fi
      fi
      PREV_AC_STATE="$IS_ON_AC"

      # Check thresholds (only when discharging)
      if [[ "$IS_ON_AC" == "false" ]]; then
        for THRESHOLD in 20 15 10 5; do
          if (( CAPACITY <= THRESHOLD )) && [[ -z "''${FIRED[$THRESHOLD]:-}" ]]; then
            case $THRESHOLD in
              20)
                URGENCY=normal
                ICON="battery-low"
                MSG="Battery at ''${CAPACITY}% — consider plugging in."
                ;;
              15)
                URGENCY=normal
                ICON="battery-low"
                MSG="Battery at ''${CAPACITY}% — plug in soon."
                ;;
              10)
                URGENCY=critical
                ICON="battery-empty"
                MSG="Battery at ''${CAPACITY}% — plug in now!"
                ;;
               5)
                URGENCY=critical
                ICON="battery-empty"
                MSG="Battery at ''${CAPACITY}% — save your work immediately!"
                ;;
            esac
            $NOTIFY_SEND --urgency="$URGENCY" --icon="$ICON" \
              "Low Battery" "$MSG"
            FIRED[$THRESHOLD]=1
          fi
        done
      fi

      sleep "$INTERVAL"
    done
  '';
in {
  home.packages = [pkgs.libnotify];

  systemd.user.services.battery-notify = {
    Unit = {
      Description = "Battery level notification monitor";
      PartOf = ["graphical-session.target"];
      BindsTo = ["graphical-session.target"];
      After = ["graphical-session.target"];
    };

    Service = {
      ExecStart = "${batteryNotifyScript}";
      Environment = ["PATH=${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.findutils}/bin"];
      Restart = "on-failure";
      RestartSec = 5;
    };

    Install = {
      WantedBy = ["graphical-session.target"];
    };
  };
}
