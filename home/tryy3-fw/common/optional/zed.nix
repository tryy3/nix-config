{ pkgs, ... }:
{
  # Zed editor — pulled from nixpkgs-unstable so we stay close to upstream releases.
  # The `pkgs.unstable` attribute is provided by the unstable-packages overlay
  # in overlays/default.nix.
  #
  # ─── How config is layered ───────────────────────────────────────────────────
  # Global user settings  → managed here   (~/.config/zed/settings.json)
  # Global user keymaps   → managed here   (~/.config/zed/keymap.json)
  # Per-project settings  → committed to each project's repo at .zed/settings.json
  #                         (NOT managed by Nix — they belong to the project)
  #
  # ─── Extensions ──────────────────────────────────────────────────────────────
  # Zed extensions are NOT Nix packages. The `extensions` list below is written
  # into `auto_install_extensions` in settings.json; Zed itself downloads them
  # on first launch into its data dir. All extensions are global — there is no
  # per-project extension list in Zed. Just list every extension you ever use;
  # they only activate for matching file types.
  #
  # ─── Per-project tooling (LSPs, formatters, compilers) ───────────────────────
  # Use the project's own flake.nix + .envrc (`use flake`). Direnv is already
  # enabled in home/tryy3-fw/common/core/direnv.nix, and the "direnv" Zed
  # extension below makes Zed pick up tools from the project's dev shell.
  programs.zed-editor = {
    enable = true;
    package = pkgs.unstable.zed-editor;

    extensions = [
      "nix"
      "toml"
      "direnv"
      "git-firefly"
      "html"
      "dockerfile"
      "dracula"
    ];

    userSettings = {
      # Privacy
      telemetry = {
        diagnostics = false;
        metrics = false;
      };

      # Look & feel
      theme = "Dracula";
      ui_font_size = 16;
      buffer_font_size = 14;
      buffer_font_family = "JetBrainsMono Nerd Font";

      # Editor behavior
      vim_mode = true;
      tab_size = 4;
      relative_line_numbers = true;
      restore_on_startup = "last_session";

      # Picks up tools from the project's nix-direnv shell.
      load_direnv = "shell_hook";

      # Format is on by default with the ability to turn it off in each project
      # if desired, in general it's a good practice to keep it on
      # .zed/settings.json (e.g. { "format_on_save": "on" }).
      format_on_save = "on";

      # Disable auto-update — Nix manages the binary.
      auto_update = false;

      # Quieter file tree
      file_scan_exclusions = [
        "**/.git"
        "**/.direnv"
        "**/result"
        "**/result-*"
        "**/.devenv"
        "**/node_modules"
        "**/target"
      ];
    };

    userKeymaps = [
      # Add personal keybindings here, e.g.:
      # {
      #   context = "Editor";
      #   bindings = { "ctrl-shift-p" = "command_palette::Toggle"; };
      # }
    ];
  };
}
