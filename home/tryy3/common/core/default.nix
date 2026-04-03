#FIXME: Move attrs that will only work on linux to nixos.nix
{
  config,
  lib,
  pkgs,
  hostSpec,
  ...
}:
let
  platform = if hostSpec.isDarwin then "darwin" else "nixos";
in
{
  imports = lib.flatten [
    (map lib.custom.relativeToRoot [
      "modules/common/host-spec.nix"
      "modules/home"
    ])
    (lib.custom.scanPathsFilterPlatform ./.)
    # TODO: Focus is WSL now but this might be a solution to use same nix for everything
    # then do special cases between WSL and regular linux, darwin could be ignored
    # ./${patform}.nix

    # # FIXME(starter): add/edit as desired
    # # Consider adding `(lib.custom.scanPathsFilterPlatform ./.)`
    # ./bash.nix
    # ./bat.nix
    # ./darwin.nix
    # ./direnv.nix
    # ./fonts.nix
    # ./git.nix
    # ./kitty.nix
    # ./nixos.nix
    # ./ssh.nix
  ];

  inherit hostSpec;

  services.ssh-agent.enable = true;

  home = {
    username = lib.mkDefault config.hostSpec.username;
    homeDirectory = lib.mkDefault config.hostSpec.home;
    stateVersion = lib.mkDefault "24.11";
    sessionPath = [
      "$HOME/.local/bin"
    ];
    sessionVariables = {
      FLAKE = "$HOME/src/nix/nix-config";
      SHELL = "bash";
    };
  };

  home.packages = builtins.attrValues {
    inherit (pkgs)

      # FIXME(starter): add/edit as desired
      # Packages that don't have custom configs go here
      curl
      pciutils
      pfetch # system info
      pre-commit # git hooks
      p7zip # compression & encryption
      usbutils
      unzip # zip extraction
      unrar # rar extraction
      bat # cat replacement
      vim
      neovim
      ripgrep
      eza # ls replacement
      dust # disk usage - alternative to du
      duf # disk usage - alternative to df
      ncdu # TUI for above
      fd # alternative to find
      cheat
      tldr
      httpie # I should learn this
      zoxide # Modernr alternative to cd
      neofetch # who knows
      ;
  };

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

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
}
