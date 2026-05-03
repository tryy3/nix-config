{
  config,
  pkgs,
  lib,
  osConfig,
  ...
}:
{
  home.packages = [
    pkgs.rmtrash
    pkgs.fzf
    pkgs.fd
    pkgs.ripgrep
  ];

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    options = [
      "--cmd cd"
    ];
  };

  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    defaultOptions = [
      "--height 40%;"
      "--border"
      "--reverse"
    ];
  };

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    settings = {
      add_newline = true;
      command_timeout = 1000;
      directory.truncation_length = 5;
      git_status.style = "bold red";
      nix_shell.format = "via [$symbol$state]($style) ";
    };
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      cat = "bat";
      ls = "eza";
      zed = "zeditor";
    };
    initExtra = "";
  };

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
      plugins = [
        "git"
        "sudo"
        "extract"
        "command-not-found"
      ];
      extraConfig = ''

        # Display red dots whilst waiting for completion.
                COMPLETION_WAITING_DOTS="true"
      '';
    };

    shellAliases = import ./aliases.nix { inherit osConfig; };
  };
}
