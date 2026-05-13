# modules/features/ai-stack/hermes/home.nix
#
# Home Manager configuration for Hermes CLI access.
{
  osConfig,
  ...
}:
let
  hasProxy = osConfig.services ? "manifest-proxy" && osConfig.services.manifest-proxy.enable;
  openaiBaseUrl = if hasProxy then "http://localhost:2099/v1" else "";
in
{
  home.sessionVariables = {
    HERMES_OPENAI_BASE_URL = openaiBaseUrl;
  };

  programs.zsh.shellAliases = {
    # Hermes quick access
    hq = "hermes ask";
    hc = "hermes chat";
    ha = "hermes agent";
  };
}
