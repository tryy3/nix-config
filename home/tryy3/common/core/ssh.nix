# FIXME(starter): adjust to you security requirements
{
  config,
  ...
}:
{
  programs.ssh = {
    enable = true;

    matchBlocks = {
      "*" = {
        # Avoids infinite hang if control socket connection interrupted. ex: vpn goes down/up
        serverAliveCountMax = 3;
        serverAliveInterval = 5; # 3 * 5s
        hashKnownHosts = true;
        controlPersist = "20m";
        controlPath = "${config.home.homeDirectory}/.ssh/sockets/S.%r@%h:%p";
        addKeysToAgent = "yes";
        controlMaster = "auto";
      };
    };
  };
  home.file = {
    ".ssh/config.d/.keep".text = "# Managed by Home Manager";
    ".ssh/sockets/.keep".text = "# Managed by Home Manager";
  };
}
