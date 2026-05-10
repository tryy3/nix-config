# modules/features/steam/default.nix
#
# Steam feature: Valve's Steam gaming client + 32-bit graphics support.
#
# Enables programs.steam (which installs the client and sets up the
# FHS environment) and hardware.graphics.enable32Bit so that 32-bit
# games can use the GPU drivers.
{ config, ... }:
let
  username = config.hostSpec.username;
in
{
  # Steam client + FHS compatibility wrapper
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports for SRCDS
    localNetworkGameTransfers.openFirewall = true; # Open ports for local game transfers
  };

  # 32-bit graphics libraries (required by many Steam / Proton games)
  hardware.graphics.enable32Bit = true;

  # HM wiring
  home-manager.users.${username}.imports = [ ./home.nix ];
}
