# FIXME(starter): the declarations here will ONLY be applied to Linux-based machines.
# Core home functionality that will only work on Linux
{
  pkgs,
  ...
}:
{
  home.sessionVariables = {
    SHELL = "zsh";
    VISUAL = "nvim";
    EDITOR = "nvim";
  };

  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-tty;
  };
}
