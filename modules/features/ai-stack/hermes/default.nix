# modules/features/ai-stack/hermes/default.nix
#
# Hermes agent — barebone core configuration.
#
# Common settings shared across all hosts that use Hermes.
# Host-specific overrides (model provider, Discord channels, etc.) belong in
# the host declaration file.
{
  config,
  lib,
  ...
}:
let
  hostSpec = config.hostSpec;
  username = hostSpec.username;
in
{
  # Wire Home Manager config
  home-manager.users.${username}.imports = [ ./home.nix ];

  users.users.${username}.extraGroups = [ "hermes" ];

  services.hermes-agent = {
    enable = true;
    environmentFiles = lib.mkIf (config.sops.secrets ? "hermes-env") [
      config.sops.secrets."hermes-env".path
    ];
    addToSystemPackages = true;

    settings = {
      toolsets = [ "all" ];

      memory = {
        enabled = true;
        user_profile_enabled = true;
        provider = "holographic";
      };

      plugins = {
        hermes-memory-store = {
          auto_extract = true;
        };
      };
    };
  };
}
