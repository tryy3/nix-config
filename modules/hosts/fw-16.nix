# modules/hosts/fw-16.nix
#
# fw-16 host configuration.
# Declares which features this host needs.
{ config, lib, ... }:
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

    # === AI tools ===
    ../features/pi
    ../features/tts

    # === AI Stack ===
    ../features/ai-stack/hermes
    ../features/ai-stack/proxy
    ../features/ai-stack/memory

    # === Hardware + host-specific config ===
    ../../hosts/nixos/fw-16
  ];

  hostSpec = {
    hostName = "fw-16";
  };

  # Enable Manifest proxy
  services.manifest-proxy.enable = true;

  # Enable ByteRover memory
  ai-stack.memory.enable = true;

  # fw-16-specific Hermes config: point at local Manifest proxy
  services.hermes-agent = {
    settings.model = {
      default = "manifest/auto";
      provider = "openai";
    };
    environmentFiles = lib.mkIf (config.sops.secrets ? "hermes-api-key") [
      config.sops.secrets."hermes-api-key".path
    ];
    environment = {
      OPENAI_BASE_URL = "http://localhost:2099/v1";
      GATEWAY_ALLOW_ALL_USERS = "true";
      API_SERVER_ENABLED = "true";
    };
  };
}
