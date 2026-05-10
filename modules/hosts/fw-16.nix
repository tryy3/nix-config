# modules/hosts/fw-16.nix
#
# fw-16 host configuration.
# Declares which features this host needs.
{ ... }:
{
  imports = [
    # === Base (always needed) ===
    ../base

    # === Shared features ===
    ../features/shell
    ../features/git
    ../features/fonts
    ../features/ghostty
    ../features/direnv
    ../features/bat
    ../features/glances
    ../features/ssh
    ../features/sops

    # === Desktop features ===
    ../features/desktop
    ../features/desktop/mango/ext # Switch to mango/ext to try the extended fork
    ../features/desktop/greeter.nix
    ../features/browsers
    ../features/lm-studio
    ../features/zed
    ../features/obsidian

    # === Gaming ===
    ../features/steam

    # === Bluetooth ===
    ../features/bluetooth

    # === Network features ===
    ../features/openssh
    ../features/podman
    ../features/tailscale
    ../features/syncthing

    # === Hardware + host-specific config ===
    ../../hosts/nixos/fw-16
  ];

  hostSpec = {
    hostName = "fw-16";
  };
}
