# FIXME(starter): the declarations here will ONLY be applied to Linux-based machines.
# Core home functionality that will only work on Linux
{
  ...
}:
{
  home.sessionVariables = {
    SHELL = "zsh";
    VISUAL = "nvim";
    EDITOR = "nvim";
  };

  services.ssh-agent.enable = true;
}
