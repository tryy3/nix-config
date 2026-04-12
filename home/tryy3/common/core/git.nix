# git is core no matter what but additional settings may could be added made in optional/foo   eg: development.nix
{
  pkgs,
  ...
}:
{
  programs.git = {
    enable = true;
    package = pkgs.gitFull;

    extraConfig = {
      userName = "tryy3"; # Consider changing this to nexer? or maybe 2 different users?s
      userEmail = "github.com@compilethis.eu";
      push.autoSetupRemote = true;
    };

    ignores = [
      ".csvignore"
      # nix
      "*.drv"
      "result"
      # python
      "*.py?"
      "__pycache__/"
      ".venv/"
      # direnv
      ".direnv"
    ];
  };

}
