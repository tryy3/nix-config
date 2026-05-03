# modules/base/user.nix
#
# Primary user configuration.
# Replaces hosts/common/users/primary/default.nix + nixos.nix.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  hostSpec = config.hostSpec;
  username = hostSpec.username;

  pubKeys = lib.filter (f: lib.hasSuffix ".pub" (toString f)) (
    lib.filesystem.listFilesRecursive ./keys
  );

  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;

  sopsHashedPasswordFile = lib.optionalString (
    !config.hostSpec.isMinimal
  ) config.sops.secrets."passwords/${username}".path;
in
{
  users.users.${username} = {
    name = username;
    home = "/home/${username}";
    isNormalUser = true;
    shell = pkgs.zsh;
    hashedPasswordFile = sopsHashedPasswordFile;

    openssh.authorizedKeys.keys = lib.lists.forEach pubKeys (key: builtins.readFile key);

    extraGroups = lib.flatten [
      "wheel"
      (ifTheyExist [
        "audio"
        "video"
        "docker"
        "git"
        "networkmanager"
        "scanner"
        "lp"
      ])
    ];
  };

  users.mutableUsers = false;

  # Root mirrors primary user
  users.users.root = {
    shell = pkgs.bash;
    hashedPasswordFile = config.users.users.${username}.hashedPasswordFile;
    hashedPassword = config.users.users.${username}.hashedPassword;
    openssh.authorizedKeys.keys = config.users.users.${username}.openssh.authorizedKeys.keys;
  };

  # SSH sockets directory
  systemd.tmpfiles.rules =
    let
      user = config.users.users.${username}.name;
      group = config.users.users.${username}.group;
    in
    [
      "d /home/${username}/.ssh 0750 ${user} ${group} -"
      "d /home/${username}/.ssh/sockets 0750 ${user} ${group} -"
    ];

  # Enable zsh at system level (required for login shell)
  programs.zsh.enable = true;
  programs.git.enable = true;

  # Wire base Home Manager config for the primary user
  home-manager.users.${username}.imports = [ ./home.nix ];
}
