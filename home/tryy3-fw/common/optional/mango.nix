# Home-manager configuration for MangoWC.
# Pair with hosts/common/optional/mango.nix for the system-level enablement.
{ inputs, ... }:
{
  imports = [
    inputs.mango.hmModules.mango
  ];

  wayland.windowManager.mango = {
    enable = true;
    # FIXME: replace with desired config (see upstream config.conf for reference)
    settings = ''
      # see config.conf
    '';
    # FIXME: replace with desired autostart commands (no shebang)
    autostart_sh = ''
      # see autostart.sh
    '';
  };
}
