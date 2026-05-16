# modules/features/lm-studio/default.nix
#
# LM Studio feature: local LLM runner desktop app.
{config, ...}: let
  username = config.hostSpec.username;
in {
  home-manager.users.${username}.imports = [./home.nix];
}
