# modules/features/bluetooth/home.nix
#
# Home Manager Bluetooth configuration.
{pkgs, ...}: {
  home.packages = with pkgs; [
    blueman # Bluetooth manager GUI (works on Wayland)
  ];
}
