# NOTE(starter): configure your audio needs as required.
{ pkgs, ... }:
{
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber = {
      enable = true;
      extraConfig = {
        # Framework 16 (ALC285): default to Speaker profile instead of Headphones
        "10-fw16-speaker-profile" = {
          "wireplumber.settings" = {
            "device.restore-profile" = false;
          };
          "monitor.alsa.rules" = [
            {
              matches = [
                { "device.name" = "alsa_card.pci-0000_c2_00.6"; }
              ];
              actions = {
                update-props = {
                  "device.profile" = "HiFi (Mic1, Mic2, Speaker)";
                };
              };
            }
          ];
        };
      };
    };
    jack.enable = true;
  };

  environment.systemPackages = builtins.attrValues {
    inherit (pkgs)
      playerctl # cli utility and lib for controlling media players
      # pamixer # cli pulseaudio sound mixer
      ;
  };
}
