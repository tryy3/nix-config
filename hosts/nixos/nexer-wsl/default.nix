# This is an example nixos hosts module.
# They will automatically be imported below.

#############################################################
#
#  Hostname1 - Example Desktop
#
###############################################################

{
  inputs,
  lib,
  ...
}:
{
  imports = lib.flatten [
    inputs.nixos-wsl.nixosModules.default

    (map lib.custom.relativeToRoot [
      #
      # ========== Required Configs ==========
      #
      "hosts/common/core"

      #
      # ========== Non-Primary Users to Create ==========
      #
      # FIXME(starter): the primary user, defined in `nix-config/hosts/common/users`, is added by default, via
      # `hosts/common/core` above.
      # To create additional users, specify the path to their config file, as shown in the commented line below, and create/modify
      # the specified file as required. See `nix-config/hosts/common/users/exampleSecondUser` for more info.

      #"hosts/common/users/exampleSecondUser"

      #
      # ========== Optional Configs ==========
      #
      # FIXME(starter): add or remove any optional host-level configuration files the host will use
      # The following are for example sake only and are not necessarily required.
      "hosts/common/optional/services/openssh.nix" # allow remote SSH access
      "hosts/common/optional/services/podman.nix" # podman container runtime
      "hosts/common/optional/audio.nix" # pipewire and cli controls
      "hosts/common/optional/xfce.nix" # lightweight x-based window manager
    ])
  ];

  #
  # ========== Host Specification ==========
  #

  # FIXME(starter): declare any host-specific hostSpec options. Note that hostSpec options pertaining to
  # more than one host can be declared in `nix-config/hosts/common/core/` see the default.nix file there
  # for examples.
  hostSpec = {
    hostName = "nexer-wsl";
  };

  wsl.enable = true;
  wsl.defaultUser = "tryy3";

  networking = {
    networkmanager.enable = true;
    enableIPv6 = false;
  };

  nixpkgs.hostPlatform = "x86_64-linux";

  # WSL doesn't use a traditional boot loader
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.grub.enable = lib.mkForce false;
  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.11";
}
