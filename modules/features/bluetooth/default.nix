# modules/features/bluetooth/default.nix
#
# Bluetooth feature: bluez daemon + user-level management tools.
{ config, ... }:
let
  username = config.hostSpec.username;
in
{
  # Enable Bluetooth daemon (bluez)
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # Wire Home Manager config
  home-manager.users.${username}.imports = [ ./home.nix ];
}
