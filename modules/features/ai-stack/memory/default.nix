# modules/features/ai-stack/memory/default.nix
#
# ByteRover persistent AI memory — CLI tool with hierarchical context tree.
#
# ByteRover (brv) provides curated, version-controlled knowledge that AI
# agents can query and update.  It runs as a CLI with an auto-starting
# daemon — no system-level service configuration needed.
#
# Provider setup is done interactively after installation:
#   brv providers connect openai-compatible --base-url http://localhost:2099/v1
#
# Architecture:
#   - NixOS level: minimal (just wires HM config)
#   - Home Manager level (home.nix): package, aliases, env vars
{
  config,
  lib,
  ...
}: let
  username = config.hostSpec.username;
in {
  options.ai-stack.memory = {
    enable = lib.mkEnableOption "ByteRover persistent AI memory (brv CLI)";
  };

  config = lib.mkIf config.ai-stack.memory.enable {
    # Wire Home Manager config
    home-manager.users.${username}.imports = [./home.nix];
  };
}
