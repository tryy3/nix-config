# hosts/nixos/nexer-wsl/default.nix
#
# nexer-wsl hardware and host-specific configuration.
# Feature imports are in modules/hosts/nexer-wsl.nix.
{
  inputs,
  lib,
  ...
}:
{
  imports = [
    inputs.nixos-wsl.nixosModules.default
    inputs.hermes-agent.nixosModules.default
    ./hermes.nix
  ];

  wsl.enable = true;
  wsl.defaultUser = "tryy3";

  # Required for running pre-compiled non-Nix binaries
  programs.nix-ld.enable = true;

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
