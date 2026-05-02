{
  config,
  lib,
  ...
}:
{
  programs.ghostty = {
    enable = true;
    # Use DMS matugen-generated theme
    # DMS generates colors at ~/.config/ghostty/config-dankcolors
    settings = {
      theme = "dankcolors";
    };
  };

  # Fix for dead keys (tilde, backtick, etc.) not working in Ghostty on Wayland
  # https://github.com/ghostty-org/ghostty/issues/2981
  # The Wayland input module doesn't handle dead keys correctly with Swedish layout.
  # Using GTK's simple input module fixes AltGr combinations for ~ ` ^ " characters.
  home.sessionVariables = lib.mkIf config.programs.ghostty.enable {
    GTK_IM_MODULE = "simple";
  };
}
