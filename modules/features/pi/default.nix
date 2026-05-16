# modules/features/pi/default.nix
#
# Pi coding agent — minimal terminal agent harness with multi-provider LLM
# support, extensible skills/extensions, and tree-structured sessions.
#
# Architecture:
#   - NixOS level: minimal (just wires HM config)
#   - Home Manager level (home.nix): package, nodejs for extension deps
#
# Pi stores all runtime state under ~/.pi/ — sessions, auth, settings,
# extensions, skills — so those paths are intentionally not managed by Nix.
# This lets you freely experiment with extensions and skills (pi install,
# /reload, editing files) without rebuilds.
{ config, ... }:
let
  username = config.hostSpec.username;
in
{
  home-manager.users.${username}.imports = [ ./home.nix ];
}
