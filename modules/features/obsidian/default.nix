# modules/features/obsidian/default.nix
#
# Obsidian feature: knowledge base / note-taking app.
#
# The vault is expected at ~/sync/obsidian-vault-01/ (synced via Syncthing).
# A shell alias `wiki` navigates there (defined in shell/aliases.nix).
{config, ...}: let
  username = config.hostSpec.username;
in {
  home-manager.users.${username}.imports = [./home.nix];
}
