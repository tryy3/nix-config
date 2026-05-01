# FIXME(starter): customize your bash preferences here
{
  programs.bash = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      cat = "bat";
      ls = "eza";
      # nixpkgs renames the zed binary to `zeditor` (collides with zsh's `zed` builtin).
      zed = "zeditor";
    };

    initExtra = "";
  };
}
