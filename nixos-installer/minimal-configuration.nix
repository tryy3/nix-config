{
  inputs,
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    (lib.custom.relativeToRoot "modules/features/host-spec.nix")
  ];

  hostSpec = {
    isMinimal = lib.mkForce true;
    hostName = "installer";
    domain = "local";
    userFullName = "Installer User";
    handle = "installer";
    # FIXME(starter): Add your primary username or whatever user you want to use for installation
    username = "hiro";
  };

  # Create the user (replaces old hosts/common/users/primary import)
  users.users.${config.hostSpec.username} = {
    isNormalUser = true;
    home = "/home/${config.hostSpec.username}";
    shell = pkgs.bash;
    extraGroups = ["wheel" "networkmanager"];
    # FIXME(starter): Add your SSH public key(s) here
    openssh.authorizedKeys.keys = [];
  };

  # Mirror root user's SSH keys from the primary user
  users.users.root.openssh.authorizedKeys.keys =
    config.users.users.${config.hostSpec.username}.openssh.authorizedKeys.keys;

  fileSystems."/boot".options = ["umask=0077"]; # Removes permissions and security warnings.
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot = {
    enable = true;
    # we use Git for version control, so we don't need to keep too many generations.
    configurationLimit = lib.mkDefault 3;
    # pick the highest resolution for systemd-boot's console.
    consoleMode = lib.mkDefault "max";
  };
  boot.initrd = {
    systemd.enable = true;
    systemd.emergencyAccess = true; # Don't need to enter password in emergency mode
  };
  boot.kernelParams = [
    "systemd.setenv=SYSTEMD_SULOGIN_FORCE=1"
    "systemd.show_status=true"
    #"systemd.log_level=debug"
    "systemd.log_target=console"
    "systemd.journald.forward_to_console=1"
  ];

  environment.systemPackages = builtins.attrValues {
    inherit
      (pkgs)
      wget
      curl
      rsync
      git
      ;
  };

  networking = {
    networkmanager.enable = true;
  };

  services = {
    qemuGuest.enable = true;
    openssh = {
      enable = true;
      ports = [22];
      settings.PermitRootLogin = "yes";
      authorizedKeysFiles = lib.mkForce ["/etc/ssh/authorized_keys.d/%u"];
    };
  };

  nix = {
    # registry and nixPath shouldn't be required here because flakes but removal results in warning spam on build
    registry = lib.mapAttrs (_: value: {flake = value;}) inputs;
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      warn-dirty = false;
    };
  };

  system.stateVersion = "24.11";
}
