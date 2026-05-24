# modules/features/bluetooth/default.nix
#
# Bluetooth feature: bluez daemon + user-level management tools.
#
# Contains the btusb workaround for Framework 16 (MediaTek MT7925)
# where autosuspend and driver binding issues break Bluetooth after
# certain kernel versions.
{config, ...}: let
  username = config.hostSpec.username;
in {
  # Enable Bluetooth daemon (bluez)
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  # ── btusb workaround (Framework 16 / MediaTek MT7925) ────────────────
  # Prevents autosuspend from breaking the btusb driver after resume.
  # boot.extraModprobeConfig = ''
  #   options btusb enable_autosuspend=N
  # '';

  # Rebinds the MediaTek MT7925 Bluetooth USB device (0e8d:0717) to the
  # btusb driver. Some kernels fail to bind it automatically on probe.
  # services.udev.extraRules = ''
  #   ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0e8d", ATTR{idProduct}=="0717", RUN+="/bin/sh -c 'echo 0e8d 0717 > /sys/bus/usb/drivers/btusb/new_id'"
  # '';

  # Wire Home Manager config
  home-manager.users.${username}.imports = [./home.nix];
}
