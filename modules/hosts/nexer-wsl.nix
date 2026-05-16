# modules/hosts/nexer-wsl.nix
#
# nexer-wsl host configuration.
# Declares which features this host needs.
{...}: {
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

    # === AI Stack ===
    ../features/ai-stack/hermes

    # === Hardware + host-specific config ===
    ../../hosts/nixos/nexer-wsl
  ];

  hostSpec = {
    hostName = "nexer-wsl";
    nixConfigPath = "/home/tryy3/nix-config";
  };

  # nexer-wsl-specific Hermes config: direct Copilot provider
  services.hermes-agent = {
    settings.model = {
      default = "claude-sonnet-4.6";
      provider = "copilot";
    };
    settings.discord = {
      free_response_channels = "1493224843347234857";
      auto_thread = true;
    };
    environment = {
      GATEWAY_ALLOW_ALL_USERS = "true";
    };
  };
}
