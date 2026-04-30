{ config, ... }:
{
  users.users.${config.hostSpec.username}.extraGroups = [ "hermes" ];

  services.hermes-agent = {
    enable = true;
    environmentFiles = [ config.sops.secrets."hermes-env".path ];
    environment = {
      GATEWAY_ALLOW_ALL_USERS = "true";
    };
    addToSystemPackages = true;
    settings = {
      model = {
        default = "claude-sonnet-4.6";
        provider = "copilot";
      };
      toolsets = [ "all" ];

      discord = {
        free_response_channels = "1493224843347234857";
        auto_thread = true;
      };

      memory = {
        enabled = true;
        user_profile_enabled = true;
        memory_char_limit = 2200; # ~800 tokens
        user_char_limit = 1375; # ~500 tokens
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
