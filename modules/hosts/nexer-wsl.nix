# modules/hosts/nexer-wsl.nix
#
# nexer-wsl host configuration.
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
    ../features/ssh
    ../features/sops

    # === WSL-specific features ===
    ../features/kubernetes

    # === Hardware + host-specific config ===
    ../../hosts/nixos/nexer-wsl
  ];

  hostSpec = {
    hostName = "nexer-wsl";
    nixConfigPath = "/home/tryy3/nix-config";
  };
}
