{
  pkgs,
  ...
}:

{
  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    iconTheme = {
      name = "elementary-Xfce-dark";
      package = pkgs.elementary-xfce-icon-theme;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  # Ensure Qt apps also use dark theme
  qt = {
    enable = true;
    platformTheme.name = "adwaita";
    style = {
      name = "adwaita-dark";
      package = pkgs.adwaita-qt;
    };
  };

  # Session variables for consistent theming across apps
  home.sessionVariables = {
    # GTK_THEME is read by many apps to determine dark/light preference
    GTK_THEME = "Adwaita:dark";
    # Qt apps should follow the dark theme
    QT_STYLE_OVERRIDE = "adwaita-dark";
    # Enable dark mode for Electron/Chrome apps
    ELECTRON_FORCE_DARK_MODE = "1";
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  # XDG Desktop Portal configuration for proper dark theme detection
  # This helps browsers and flatpak apps detect the system theme preference
  xdg.configFile."xdg-desktop-portal/gtk.conf".text = ''
    [settings]
    gtk-theme=Adwaita-dark
  '';
}
