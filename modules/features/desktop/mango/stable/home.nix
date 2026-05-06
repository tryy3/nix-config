# modules/features/desktop/mango/stable/home.nix
#
# Home Manager configuration for the stable (upstream) MangoWC compositor.
# Imports the upstream HM module, the shared mango config, and adds binds
# that differ from the ext variant.
{ inputs, ... }:
{
  imports = [
    inputs.mango.hmModules.mango
    ../common.nix
  ];

  wayland.windowManager.mango.settings = {
    # Keybinds that are overridden in the ext variant by canvas features
    bind = [
      "SUPER,o,toggleoverlay,"
      "SUPER,u,focuslast"
    ];

    # Layouts available in the cycle (SUPER+n switches to next)
    circle_layout = "tile,scroller";

    # Upstream mango uses generic accel_profile/accel_speed for both
    # mouse and trackpad. mango-ext splits these into mouse_accel_profile
    # and trackpad_accel_profile.
    accel_profile = 2;
    accel_speed = 0.0;
  };
}
