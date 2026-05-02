# Bitwarden desktop + browser integration with biometric (fingerprint) unlock.
#
# What this enables, and why each piece is necessary:
#
# 1. bitwarden-desktop installed system-wide
#    The package ships a polkit policy at
#    share/polkit-1/actions/com.bitwarden.Bitwarden.policy. Polkit only scans
#    system-wide paths, so a home-manager install leaves the polkit action
#    permanently unregistered.
#
# 2. /etc/mozilla/native-messaging-hosts/com.8bit.bitwarden.json
#    Canonical system-wide location for the native messaging manifest. Read by
#    Zen, Firefox, LibreWolf, Floorp - any Mozilla-family browser.
#
# 3. polkit-1 PAM service gets fprintAuth
#    On Linux Bitwarden's "biometric unlock" is actually a polkit prompt. With
#    fprintAuth in the PAM stack, polkit will accept a fingerprint instead of
#    asking for the password.
#
# 4. GNOME Keyring (the critical missing piece)
#    Bitwarden's biometric toggle ONLY appears when a Secret Service provider
#    is reachable on the session DBus (org.freedesktop.secrets). The desktop
#    app calls oo7::Keyring::new() in passwords.isAvailable(); if that fails,
#    getBiometricsStatus() returns HardwareUnavailable and the toggle is
#    hidden entirely. See:
#       apps/desktop/src/key-management/biometrics/os-biometrics-linux.service.ts
#       desktop_native/core/src/password/unix.rs
#    GNOME Keyring provides org.freedesktop.secrets and is DBus-activated, so
#    it does not need a desktop environment to run. We enable PAM integration
#    on greetd + login so the keyring auto-unlocks when you log in with your
#    user password (fingerprint-only logins cannot derive the keyring key).
#
# After rebuilding (reboot recommended so the keyring/PAM picks up cleanly):
#   1. Log in once at greetd with your USER PASSWORD (not just fingerprint),
#      so PAM unlocks the keyring on first session. Subsequent logins can use
#      fingerprint - the keyring stays unlocked for the session.
#      (If you only ever log in with fingerprint you will need to set the
#      "Default" keyring password to empty via `seahorse`, otherwise the
#      keyring will be locked and Bitwarden will prompt to unlock it.)
#   2. Bitwarden desktop -> Settings -> Security  -> "Unlock with biometrics"
#   3. Bitwarden desktop -> Settings -> App       -> "Browser integration"
#                                                 -> "Require verification..."
#   4. Bitwarden extension in Zen -> Settings -> "Unlock with biometrics"
#      (desktop pops a fingerprint-code confirmation - approve it)
{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.bitwarden-desktop
    pkgs.seahorse # GUI to manage the GNOME keyring (set/clear password)
  ];

  # Native messaging manifest for Zen / Firefox / any Mozilla-family browser.
  environment.etc."mozilla/native-messaging-hosts/com.8bit.bitwarden.json".source =
    "${pkgs.bitwarden-desktop}/lib/mozilla/native-messaging-hosts/com.8bit.bitwarden.json";

  # Secret Service provider (org.freedesktop.secrets on DBus). Without this,
  # Bitwarden's biometric toggle never renders. DBus-activated - no extra
  # systemd unit needed.
  services.gnome.gnome-keyring.enable = true;

  # gnome-keyring auto-enables gcr-ssh-agent, which collides with the
  # OpenSSH agent already enabled in hosts/common/core/ssh.nix. We only want
  # the secrets/keyring side of gnome-keyring, not its SSH agent.
  services.gnome.gcr-ssh-agent.enable = false;

  # Auto-unlock the keyring when you log in with your password.
  security.pam.services.greetd.enableGnomeKeyring = true;
  security.pam.services.login.enableGnomeKeyring = true;

  # Let the polkit unlock prompt (and the keyring unlock prompt) accept a
  # fingerprint instead of asking for the user password.
  security.pam.services.polkit-1.fprintAuth = true;
}
