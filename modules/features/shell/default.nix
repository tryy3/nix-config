# modules/features/shell/default.nix
#
# Shell feature: zsh + starship + fzf + zoxide + bash.
# Enables zsh system-wide and wires the Home Manager shell config.
{
  config,
  ...
}:
let
  username = config.hostSpec.username;
in
{
  programs.zsh.enable = true;

  home-manager.users.${username}.imports = [ ./home.nix ];
}
