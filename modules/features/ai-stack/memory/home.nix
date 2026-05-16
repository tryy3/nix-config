# modules/features/ai-stack/memory/home.nix
#
# Home Manager configuration for ByteRover CLI (brv).
#
# Installs the byterover-cli package and provides shell aliases for common
# operations.  LLM provider configuration is done interactively via
# `brv providers connect` after first installation.
#
# Key directories (XDG-compliant):
#   Config:  ~/.config/brv/
#   Data:    ~/.local/share/brv/
#   Project: <project>/.brv/
{
  osConfig,
  pkgs,
  lib,
  ...
}: let
  hasProxy = osConfig.services ? "manifest-proxy" && osConfig.services.manifest-proxy.enable;
in {
  # ── Package ────────────────────────────────────────────────────────────
  home.packages = [pkgs.byterover-cli];

  # ── Shell aliases ──────────────────────────────────────────────────────
  programs.zsh.shellAliases = {
    # Quick access
    br = "brv";

    # Core workflow
    curate = "brv curate";
    memory = "brv query";

    # Version control for context tree
    bvc = "brv vc";

    # MCP server (for AI agent integration)
    brv-mcp = "brv mcp";

    # Provider management
    brv-providers = "brv providers list";
  };

  # ── Environment ─────────────────────────────────────────────────────────
  # When Manifest proxy is available, set the base URL so `brv providers
  # connect openai-compatible` can auto-detect it.  The API key still needs
  # to be provided interactively or via OPENAI_COMPATIBLE_API_KEY.
  home.sessionVariables = lib.mkIf hasProxy {
    BRV_OPENAI_COMPATIBLE_BASE_URL = "http://localhost:2099/v1";
  };
}
