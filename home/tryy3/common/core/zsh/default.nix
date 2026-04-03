{
  config,
  pkgs,
  lib,
  osConfig,
  ...
}:
{
  # Adding these packages here because they are tied to zsh
  home.packages = [
    pkgs.rmtrash # temporarily cache deleted files for recovery
    pkgs.fzf # fuzzy finder
  ];
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    options = [
      "--cmd cd" # replacce cd with z and zi (via cdi)
    ];
  };

  #
  # Actual zsh options
  #
  programs.zsh = {
    enable = true;

    dotDir = "${config.xdg.configHome}/zsh";
    enableCompletion = true;
    syntaxHighlighting = {
      enable = true;
    };
    autocd = true;
    autosuggestion = {
      enable = true;
    };
    history = {
      size = 10000;
      share = true;
    };

    plugins = import ./plugins.nix { inherit pkgs; };

    initContent = lib.mkAfter (lib.readFile ./zshrc);
    oh-my-zsh = {
      enable = true;
      # Standard OMZ plugins pre-installed to $ZSH/plugins/
      # Custom OMZ plugins are addded to $ZSH_CUSTOM/plugins/
      # Enabling too many plugins will slowdown shell startup
      plugins = [
        "git"
        # "sudo" # Press Esc twice to get previous command preffixed with sudo
      ];
      extraConfig = ''
        # Display red dots whilst waiting for completion.
                COMPLETION_WAITING_DOTS="true"
      '';
    };

    shellAliases = import ./aliases.nix { inherit osConfig; };
  };
}
