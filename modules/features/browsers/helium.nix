# modules/features/browsers/helium.nix
#
# Helium Browser — private, fast, and honest web browser.
# NOTE: No declarative settings. Configure Helium directly in the browser.
{
  pkgs,
  inputs,
  ...
}: {
  home.packages = [inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.default];

  # Set Helium as the default browser
  xdg.mimeApps.defaultApplications = {
    "text/html" = ["helium.desktop"];
    "text/xml" = ["helium.desktop"];
    "x-scheme-handler/http" = ["helium.desktop"];
    "x-scheme-handler/https" = ["helium.desktop"];
  };
}
