{...}: {
  programs.firefox = {
    enable = true;
  };

  xdg.mimeApps.defaultApplications = {
    "text/html" = ["zen-twilight.desktop"];
    "text/xml" = ["zen-twilight.desktop"];
    "x-scheme-handler/http" = ["zen-twilight.desktop"];
    "x-scheme-handler/https" = ["zen-twilight.desktop"];
  };
}
