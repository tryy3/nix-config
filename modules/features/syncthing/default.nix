# modules/features/syncthing/default.nix
#
# Syncthing feature: P2P file sync daemon.
#
# Runs as the primary user so it can access files in the home directory
# (e.g. Obsidian vaults). The web GUI is reachable on all interfaces,
# which means it's accessible from Tailscale peers since tailscale0 is
# a trusted interface (configured in the tailscale feature module).
#
# Ports opened:
#   22000/tcp + 22000/udp — sync protocol (TCP + QUIC)
#   21027/udp             — local discovery
#   8384/tcp              — web GUI
{
  config,
  ...
}:
let
  username = config.hostSpec.username;
  homeDir = config.hostSpec.home;
in
{
  services.syncthing = {
    enable = true;
    user = username;
    dataDir = "${homeDir}/.local/state/syncthing";
    configDir = "${homeDir}/.config/syncthing";

    # Open default firewall ports for local LAN sync as fallback.
    # Tailscale traffic is already allowed via trustedInterfaces.
    openDefaultPorts = true;

    settings = {
      # GUI accessible from Tailscale peers (e.g. Windows machine).
      # First-time auth is set up via the GUI itself.
      gui = {
        address = "0.0.0.0:8384";
      };
    };
  };

  # Explicit firewall rules (openDefaultPorts covers these, but being
  # explicit makes the intent clear and ensures they're always open).
  networking.firewall.allowedTCPPorts = [
    22000
    8384
  ];
  networking.firewall.allowedUDPPorts = [
    22000
    21027
  ];
}
