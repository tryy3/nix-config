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
}: {
  imports = [
    ./hardware-configuration.nix

    inputs.hardware.nixosModules.framework-16-amd-ai-300-series-nvidia

    # Hermes agent upstream NixOS module (defines services.hermes-agent option)
    inputs.hermes-agent.nixosModules.default
  ];

  # Required for running pre-compiled non-Nix binaries
  programs.nix-ld.enable = true;

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
    networkmanager = {
      enable = true;

      settings = {
        connection = {
          "wifi.powersave" = false;
        };
      };

      ensureProfiles = {
        environmentFiles = [config.sops.templates."networkmanager.env".path];
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
  };

  # ── Disable WiFi power saving at driver level ────────────────────────────
  # NM's powersave=false doesn't always propagate to the driver.
  # This runs on boot and after every resume to keep power_save off.
  systemd.services."wifi-powersave-off" = {
    description = "Disable WiFi power saving";
    unitConfig.ConditionPathExists = "/sys/class/net/wlan0/power_save";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.iproute2}/bin/iw dev wlan0 set power_save off";
    };
    wantedBy = [
      "network-online.target"
      "systemd-resume.target"
    ];
    after = [
      "network-online.target"
      "systemd-resume.service"
    ];
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
  boot.kernelParams = ["amdgpu.abmlevel=0"];
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
