# modules/features/pi/home.nix
#
# Home Manager configuration for Pi coding agent.
#
# ─── Key directories (all outside Nix control, intentionally mutable) ────
#   Global config:    ~/.pi/agent/settings.json
#   Global auth:      ~/.pi/agent/auth.json
#   Global skills:    ~/.pi/agent/skills/
#   Global extens:   ~/.pi/agent/extensions/
#   Global instr:    ~/.pi/agent/AGENTS.md
#   Project config:   .pi/settings.json
#   Project skills:   .pi/skills/
#   Project extens:  .pi/extensions/
#   Sessions:         ~/.pi/agent/sessions/ (or sessionDir in settings)
#
# ─── Why nodejs is included ─────────────────────────────────────────────
# Pi extensions can declare npm dependencies. When Pi installs or updates
# an extension directory that has a package.json, it runs npm install there.
# Having nodejs on PATH ensures this works without errors.
{
  pkgs,
  config,
  ...
}: {
  home.packages = builtins.attrValues {
    inherit
      (pkgs)
      pi-coding-agent
      nodejs
      ;
  };

  home.sessionPath = ["$HOME/.npm-global/bin"];

  # ── npm global prefix ──────────────────────────────────────────────────
  # npm's default prefix on NixOS points to the read-only Nix store, which
  # breaks `pi install npm:...` (runs `npm install -g`).  Setting prefix in
  # ~/.npmrc redirects global installs to a user-writable location.
  home.file = {
    ".npmrc".text = "prefix=${config.home.homeDirectory}/.npm-global\n";
    ".pi/.keep".text = "";
    ".npm-global/.keep".text = "";
  };
}
