# DankMaterialShell-based greetd greeter (login screen).
# Enables greetd with the DMS Quickshell-based greeter UI running inside
# a mango compositor session.
#
# Pair with hosts/common/optional/mango.nix and
# hosts/common/optional/dank-material-shell.nix.
#
# Reference:
#   https://github.com/AvengeMedia/DankMaterialShell/blob/master/distro/nix/greeter.nix
{
  inputs,
  config,
  pkgs,
  ...
}:
{
  imports = [
    inputs.dms.nixosModules.greeter
  ];

  programs.dank-material-shell.greeter = {
    enable = true;
    compositor.name = "mango";
    # Copy this user's DMS theme/wallpaper/session into the greeter cache
    # so the login screen visually matches the desktop.
    configHome = config.hostSpec.home;
  };

  # Hybrid GPU on the FW16 (NVIDIA dGPU + AMD iGPU). wlroots must be told
  # explicitly which DRM device to use, otherwise it may pick the NVIDIA dGPU
  # (which has no outputs) and fail with:
  #   [ERROR] swapchain.c: Failed to pick primary buffer format for output 'eDP-1'
  # producing a blank TTY. Pinning to card1 (AMD iGPU, PCI 0000:c2:00.0) fixes
  # this; wlroots then auto-selects the correct render node for that card.
  #
  # wlroots reads WLR_DRM_DEVICES during backend init, before mango parses its
  # config, so mango's `env=` block is too late — these must be in the process
  # environment before exec. There are two injection points:
  #
  # 1. The greetd unit itself (greeter session, runs as `greeter` user).
  #    Systemd units have a stripped environment with no login shell, so we
  #    inject directly via systemd.services.greetd.environment.
  #
  # 2. The user session greetd forks after login (runs as the primary user).
  #    greetd creates the session via PAM. pam_env reads /etc/environment
  #    (populated by `environment.variables`), so the user mango inherits
  #    these without needing a login shell or HM session activation.
  #
  # Additionally, /run/opengl-driver/share/glvnd/egl_vendor.d/ contains both
  # 10_nvidia.json (loaded first) and 50_mesa.json. libglvnd probes NVIDIA
  # first against the AMD GBM device, returning an incompatible buffer-format
  # set and causing the same swapchain failure. Pinning EGL to Mesa for the
  # greeter unit resolves this; the user session uses Mesa by default already.

  # Goes into /etc/environment → read by PAM pam_env for every session greetd
  # creates, including the post-login user mango session.
  environment.variables = {
    WLR_DRM_DEVICES = "/dev/dri/card1";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  # Inject into the greetd unit directly for the greeter process itself.
  # __EGL_VENDOR_LIBRARY_FILENAMES is greeter-only; the user session uses
  # Mesa/EGL correctly without it.
  systemd.services.greetd.environment = {
    WLR_DRM_DEVICES = "/dev/dri/card1";
    WLR_NO_HARDWARE_CURSORS = "1";
    __EGL_VENDOR_LIBRARY_FILENAMES = "${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json";
  };
}
