# modules/base/default.nix
#
# Base configuration applied to ALL hosts.
# Replaces hosts/common/core/default.nix, hosts/common/core/nixos.nix,
# hosts/common/core/ssh.nix, and modules/common/.
{
  inputs,
  outputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  platform = "nixos";
  platformModules = "${platform}Modules";
in
{
  imports = [
    inputs.home-manager.${platformModules}.home-manager
    inputs.sops-nix.${platformModules}.sops
    inputs.nix-index-database.nixosModules.default

    # Base sub-modules
    ./user.nix
    ./sops.nix

    # Host-spec module (defines the hostSpec option)
    ../features/host-spec.nix
  ];

  # === Home Manager defaults ===
  home-manager.useGlobalPkgs = true;
  home-manager.backupFileExtension = "bk";
  home-manager.extraSpecialArgs = {
    inherit inputs;
    hostSpec = config.hostSpec;
  };

  # === Host spec defaults ===
  hostSpec = {
    username = "tryy3";
    handle = "tryy3";
    inherit (inputs.nix-secrets)
      domain
      email
      userFullName
      networking
      ;
  };

  networking.hostName = config.hostSpec.hostName;

  # System-wide packages
  environment.systemPackages = [
    pkgs.openssh
    pkgs.just
    pkgs.rsync
  ];

  # === Overlays ===
  nixpkgs = {
    overlays = [ outputs.overlays.default ];
    config.allowUnfree = true;
  };

  # === Nix settings ===
  nix = {
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    settings = {
      connect-timeout = 5;
      log-lines = 25;
      min-free = 128000000; # 128MB
      max-free = 1000000000; # 1GB
      trusted-users = [ "@wheel" ];
      auto-optimise-store = true;
      warn-dirty = false;
      allow-import-from-derivation = false;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };

  # === Core NixOS settings (from old hosts/common/core/nixos.nix) ===
  environment.enableAllTerminfo = true;
  hardware.enableRedistributableFirmware = true;

  security.sudo.extraConfig = ''
    Defaults lecture = never
    Defaults pwfeedback
    Defaults timestamp_timeout=120
    Defaults env_keep+=SSH_AUTH_SOCK
  '';

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 20d --keep 20";
    flake = config.hostSpec.nixConfigPath;
  };

  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_TIME = "sv_SE.UTF-8";
    LC_MONETARY = "sv_SE.UTF-8";
    LC_PAPER = "sv_SE.UTF-8";
    LC_MEASUREMENT = "sv_SE.UTF-8";
  };
  time.timeZone = lib.mkDefault "Europe/Stockholm";

  # === SSH agent (from old hosts/common/core/ssh.nix) ===
  programs.ssh.startAgent = true;
  programs.ssh.enableAskPassword = true;

  # === nix-index-database ===
  programs.nix-index-database = {
    enable = true;
    comma.enable = true;
  };
}
