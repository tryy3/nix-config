# modules/base/home.nix
#
# Core Home Manager configuration applied to all hosts.
# Replaces home/tryy3/common/core/default.nix.
# hostSpec is passed via extraSpecialArgs from the NixOS module system.
{
  lib,
  pkgs,
  hostSpec,
  ...
}:
{
  services.ssh-agent.enable = true;

  home = {
    username = lib.mkDefault hostSpec.username;
    homeDirectory = lib.mkDefault hostSpec.home;
    stateVersion = lib.mkDefault "24.11";
    sessionPath = [
      "$HOME/.local/bin"
    ];
    sessionVariables = {
      FLAKE = hostSpec.nixConfigPath;
      SHELL = "zsh";
      VISUAL = "nvim";
      EDITOR = "nvim";
    };
  };

  # Core CLI packages that don't have their own feature module
  home.packages =
    builtins.attrValues {
      inherit (pkgs)
        curl
        pciutils
        pfetch
        pre-commit
        p7zip
        usbutils
        unzip
        unrar
        bat
        vim
        neovim
        ripgrep
        eza
        dust
        duf
        ncdu
        fd
        cheat
        tldr
        httpie
        zoxide
        neofetch
        wget
        zellij
        podman
        podman-compose
        gnupg
        pinentry-tty
        gh
        yazi
        wl-clipboard
        ;
    }
    ++ [
      pkgs.unstable.opencode
    ];

  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      warn-dirty = false;
    };
  };

  programs.home-manager.enable = true;

  # GPG agent for pinentry
  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-tty;
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
}
