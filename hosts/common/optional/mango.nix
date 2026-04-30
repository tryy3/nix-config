# System-level enablement of MangoWC (Wayland compositor).
# Pair with the home-manager module at home/<user>/common/optional/mango.nix
# for user-side configuration.
{ inputs, ... }:
{
  imports = [
    inputs.mango.nixosModules.mango
  ];

  programs.mango.enable = true;
}
