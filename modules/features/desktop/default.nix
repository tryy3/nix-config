# modules/features/desktop/default.nix
#
# Desktop feature: Wayland desktop shell + audio + GPU support.
#
# NOTE: The MangoWC compositor is NOT included here — it has its own variant
# modules so you can choose between stable and ext. Add one of these to your
# host declaration:
#   ../features/desktop/mango/stable   — upstream mango
#   ../features/desktop/mango/ext      — mango-ext fork (canvas, dwindle, touch)
{
  config,
  pkgs,
  ...
}:
let
  username = config.hostSpec.username;
in
{
  # Graphics support
  hardware.graphics.enable = true;

  # Dconf for GTK theming
  programs.dconf.enable = true;

  # DMS system dependencies (polkit, accounts-daemon, geoclue2, fprintd)
  services.power-profiles-daemon.enable = true;
  services.accounts-daemon.enable = true;
  services.geoclue2.enable = true;
  security.polkit.enable = true;
  services.fprintd.enable = true;
  security.pam.services.greetd.fprintAuth = false;
  security.pam.services.login.fprintAuth = true;
  security.pam.services.sudo.fprintAuth = true;

  # Audio (PipeWire)
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber = {
      enable = true;
      extraConfig = {
        "10-fw16-speaker-profile" = {
          "wireplumber.settings" = {
            "device.restore-profile" = false;
          };
          "monitor.alsa.rules" = [
            {
              matches = [
                { "device.name" = "alsa_card.pci-0000_c2_00.6"; }
              ];
              actions = {
                update-props = {
                  "device.profile" = "HiFi (Mic1, Mic2, Speaker)";
                };
              };
            }
          ];
        };
      };
    };
    jack.enable = true;
  };

  # Bitwarden desktop + browser integration + biometric unlock
  environment.systemPackages = [
    pkgs.bitwarden-desktop
    pkgs.seahorse
  ];
  environment.etc."mozilla/native-messaging-hosts/com.8bit.bitwarden.json".source =
    "${pkgs.bitwarden-desktop}/lib/mozilla/native-messaging-hosts/com.8bit.bitwarden.json";
  services.gnome.gnome-keyring.enable = true;
  services.gnome.gcr-ssh-agent.enable = false;
  security.pam.services.greetd.enableGnomeKeyring = true;
  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.polkit-1.fprintAuth = true;

  # Power management
  services.upower.enable = true;

  # ── Power management (logind) ─────────────────────────────────────────────
  # Power button: ignore accidental short presses, shutdown only on long press (~3s)
  # Lid close: suspend to RAM (fast resume, ~1-3W draw while sleeping)
  # Idle is managed by swayidle (media-aware), not logind
  services.logind.settings.Login = {
    HandlePowerKey = "ignore";
    HandlePowerKeyLongPress = "poweroff";
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    IdleAction = "ignore";
  };

  # HM wiring
  home-manager.users.${username}.imports = [ ./home.nix ];
}
