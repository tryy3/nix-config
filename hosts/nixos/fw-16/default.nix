# hosts/nixos/fw-16/default.nix
#
# fw-16 hardware and host-specific configuration.
# Feature imports are in modules/hosts/fw-16.nix.
{
  lib,
  inputs,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix

    inputs.hardware.nixosModules.framework-16-amd-ai-300-series-nvidia
  ];

  # WiFi profile (uses sops secrets)
  sops.secrets."wifi/home-psk" = {
    mode = "0400";
    owner = config.users.users.${config.hostSpec.username}.name;
    group = config.users.users.${config.hostSpec.username}.group;
  };

  sops.templates."networkmanager.env".content = ''
    HOME_PSK=${config.sops.placeholder."wifi/home-psk"}
  '';

  networking = {
    networkmanager.enable = true;

    networkmanager.ensureProfiles = {
      environmentFiles = [ config.sops.templates."networkmanager.env".path ];
      profiles.home = {
        connection = {
          id = "home";
          type = "wifi";
          autoconnect = true;
        };
        wifi = {
          ssid = "Kaktus Plantan";
          mode = "infrastructure";
        };
        wifi-security = {
          key-mgmt = "wpa-psk";
          psk = "$HOME_PSK";
        };
        ipv4.method = "auto";
        ipv6.method = "auto";
      };
    };
  };

  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = lib.mkDefault 10;
    };
    efi.canTouchEfiVariables = true;
    timeout = 3;
  };

  boot.initrd.systemd.enable = true;
  boot.kernelParams = [ "amdgpu.abmlevel=0" ];
  boot.kernelPackages = pkgs.linuxPackages_7_0;

  # Swedish keyboard (TTY only; Wayland keyboard is configured in the compositor)
  console.keyMap = "sv-latin1";

  # NVIDIA hybrid graphics
  hardware.nvidia.prime = {
    amdgpuBusId = "PCI:194:0:0"; # iGPU (AMD, 0xC2)
    nvidiaBusId = "PCI:193:0:0"; # dGPU (NVIDIA, 0xC1)
  };

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.11";
}
