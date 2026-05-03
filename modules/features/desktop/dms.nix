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
    dgop.package = inputs.dgop.packages.${pkgs.stdenv.hostPlatform.system}.default;
    # quickshell.package = pkgs.unstable.quickshell;

    # Auto-start dms via systemd user service (binds to wayland session target).
    systemd.enable = true;

    # Settings are merged into ~/.config/DankMaterialShell/settings.json.
    # Only values that differ from upstream defaults are listed here.
    settings = {
      # --- Theme ---
      currentThemeName = "dynamic";
      currentThemeCategory = "dynamic";
      matugenScheme = "scheme-expressive";
      widgetColorMode = "colorful";
      cornerRadius = 12;

      # --- Clock / Date ---
      clockDateFormat = "yyyy-MM-dd";
      lockDateFormat = "yyyy-MM-dd";

      # --- Workspace switcher ---
      showWorkspaceIndex = true;
      showWorkspaceName = true;
      showWorkspacePadding = true;
      workspaceFollowFocus = true;

      # --- Launcher ---
      launcherLogoMode = "dank";
      launcherLogoSizeOffset = 6;

      # --- Control center ---
      controlCenterShowMicPercent = true;

      # --- OSD ---
      osdPowerProfileEnabled = true;

      # --- Notifications ---
      notificationOverlayEnabled = true;

      # --- Lock screen ---
      enableFprint = true;

      # --- Dock ---
      dockMargin = 8;
      dockIconSize = 54;
      dockIndicatorStyle = "line";
      dockIsolateDisplays = true;
      dockLauncherEnabled = true;
      dockLauncherLogoMode = "dank";
      dockLauncherLogoColorOverride = "primary";

      # --- Matugen templates ---
      # Terminal emulator themes
      matugenTemplateGhostty = true; # Enable Ghostty terminal theming

      # Disabled templates for apps not in use:
      matugenTemplateNiri = false;
      matugenTemplateHyprland = false;
      matugenTemplateQt5ct = false;
      matugenTemplateQt6ct = false;
      matugenTemplatePywalfox = false;
      matugenTemplateVesktop = false;
      matugenTemplateEquibop = false;
      matugenTemplateKitty = false;
      matugenTemplateFoot = false;
      matugenTemplateAlacritty = false;
      matugenTemplateWezterm = false;
      matugenTemplateEmacs = false;

      # --- App ID substitutions (cleared; upstream default has 5 entries) ---
      appIdSubstitutions = [ ];

      # --- Desktop widget instances ---
      desktopWidgetInstances = [
        {
          id = "dw_1777635685827_r5wn1pqxe";
          widgetType = "systemMonitor";
          name = "System Monitor";
          enabled = false;
          config = {
            showHeader = true;
            transparency = 0.8;
            colorMode = "primary";
            customColor = "#ffffff";
            showCpu = true;
            showCpuGraph = true;
            showCpuTemp = true;
            showGpuTemp = true;
            gpuPciId = "10de:2d58"; # NVIDIA dGPU vendor:device ID (verify with `lspci -nn | grep NVIDIA`)
            showMemory = true;
            showMemoryGraph = true;
            showNetwork = true;
            showNetworkGraph = true;
            showDisk = true;
            showTopProcesses = false;
            topProcessCount = 3;
            topProcessSortBy = "cpu";
            layoutMode = "auto";
            graphInterval = 60;
            displayPreferences = [ "all" ];
            showOnOverlay = false;
          };
          # NOTE: positions contain per-monitor pixel coordinates and will
          # drift as you move the widget. Remove or update if they become stale.
          positions = {
            "eDP-1" = {
              width = 1014.4296875;
              height = 1084.24609375;
              x = 1535.9296875;
              y = 54.75;
            };
          };
        }
        {
          id = "dw_1777635708640_wirpq1u66";
          widgetType = "desktopClock";
          name = "Desktop Clock";
          enabled = true;
          config = {
            style = "stacked";
            transparency = 0.9;
            colorMode = "primary";
            customColor = "#ffffff";
            showDate = true;
            showAnalogNumbers = false;
            showAnalogSeconds = true;
            displayPreferences = [ "all" ];
            showOnOverlay = false;
            clickThrough = false;
          };
          positions = {
            "eDP-1" = {
              width = 200;
              height = 200;
              x = 31.3515625;
              y = 74.33203125;
            };
          };
        }
      ];

      # --- Bar configuration (changed from defaults) ---
      barConfigs = [
        {
          id = "default";
          name = "Main Bar";
          enabled = true;
          position = 0;
          screenPreferences = [ "all" ];
          showOnLastDisplay = true;
          leftWidgets = [
            "launcherButton"
            "workspaceSwitcher"
            "focusedWindow"
          ];
          centerWidgets = [
            "music"
            "clock"
            "weather"
          ];
          rightWidgets = [
            {
              id = "systemTray";
              enabled = true;
            }
            {
              id = "clipboard";
              enabled = true;
            }
            {
              id = "cpuUsage";
              enabled = true;
            }
            {
              id = "memUsage";
              enabled = true;
            }
            {
              id = "notificationButton";
              enabled = true;
            }
            {
              id = "battery";
              enabled = true;
            }
            {
              id = "vpn";
              enabled = true;
            }
            {
              id = "controlCenterButton";
              enabled = true;
            }
          ];
          spacing = 2; # def 4
          innerPadding = 8; # def 4
          bottomGap = 0;
          transparency = 0.85; # def 1.0
          widgetTransparency = 1.0;
          squareCorners = false;
          noBackground = false;
          maximizeWidgetIcons = false;
          maximizeWidgetText = false;
          removeWidgetPadding = false;
          widgetPadding = 10; # def 8
          gothCornersEnabled = false;
          gothCornerRadiusOverride = false;
          gothCornerRadiusValue = 12;
          borderEnabled = false;
          borderColor = "surfaceText";
          borderOpacity = 1.0;
          borderThickness = 1;
          widgetOutlineEnabled = false;
          widgetOutlineColor = "primary";
          widgetOutlineOpacity = 1.0;
          widgetOutlineThickness = 1;
          fontScale = 1.0;
          iconScale = 0.99; # def 1.0
          autoHide = false;
          autoHideDelay = 250;
          showOnWindowsOpen = false;
          openOnOverview = false;
          visible = true;
          popupGapsAuto = true;
          popupGapsManual = 4;
          maximizeDetection = true;
          scrollEnabled = true;
          scrollXBehavior = "column";
          scrollYBehavior = "workspace";
          shadowIntensity = 0;
          shadowOpacity = 60;
          shadowColorMode = "text"; # def "default"
          shadowCustomColor = "#000000";
          clickThrough = false;
        }
      ];

      # --- Built-in plugin settings ---
      builtInPluginSettings = {
        dms_settings_search = {
          trigger = "?";
        };
      };
    };

    # session is all defaults — nothing to override.
    session = {
      wallpaperPath = "/home/tryy3/src/nix/nix-config/assets/wallpapers/anime-coffee-shop-backiee-4K.jpg";
      wallpaperPathDark = "/home/tryy3/src/nix/nix-config/assets/wallpapers/anime-coffee-shop-backiee-4K.jpg";
    };

    clipboardSettings = {
      maxHistory = 100; # def 25
    };
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
