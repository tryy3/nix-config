# System-level dependencies for DankMaterialShell.
#
# NOTE: per the DMS docs we enable DMS in EITHER the NixOS module OR the
# home-manager module — never both, because both define
# `systemd.user.services.dms` and create competing
# `graphical-session.target.wants/dms.service` symlinks.
#
# We use the home-manager module
# (home/<user>/common/optional/dank-material-shell.nix) for actual configuration
# and the user-level dms.service. This file only declares the system services
# DMS expects (polkit, accounts-daemon, geoclue2, power-profiles).
#
# The DMS package itself reaches the system via the greeter module
# (hosts/common/optional/dank-material-shell-greeter.nix), which imports
# inputs.dms.nixosModules.greeter.
{ ... }:
{
  services.power-profiles-daemon.enable = true;
  services.accounts-daemon.enable = true;
  services.geoclue2.enable = true;
  security.polkit.enable = true;

  # Enable fprintd for fingerprint enrollment and authentication.
  # After rebuilding, run `fprintd-enroll` to register your fingerprint.
  services.fprintd.enable = true;

  # Allow fingerprint auth on the greetd login screen and the DMS lock screen.
  security.pam.services.greetd.fprintAuth = true;
  security.pam.services.login.fprintAuth = true;
  security.pam.services.sudo.fprintAuth = true;
}
