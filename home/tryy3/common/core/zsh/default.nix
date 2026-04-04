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
    pkgs.fd
    pkgs.ripgrep
  ];
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    options = [
      "--cmd cd" # replacce cd with z and zi (via cdi)
    ];
  };
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f --hiden --follow --exclude .git";
    defaultOptions = [
      "--height 40%;"
      "--border"
      "--reverse"
    ];
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = true;
      command_timeout = 1000;
      directory.truncation_length = 5;
      git_status.style = "bold red";
      nix_shell.format = "via [$symbol$state]($style) ";
    };
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
      size = 50000;
      save = 50000;
      share = true;
      ignoreDups = true;
      ignoreSpace = true;
      extended = true;
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
        "sudo" # Press Esc twice to get previous command preffixed with sudo
        "extract"
        "command-not-found"
      ];
      extraConfig = ''
        # Display red dots whilst waiting for completion.
                COMPLETION_WAITING_DOTS="true"
      '';
    };

    shellAliases = import ./aliases.nix { inherit osConfig; }; # TODO: look at oxConfig from nix-config
  };
}
