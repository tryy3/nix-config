# git is core no matter what but additional settings may could be added made in optional/foo   eg: development.nix
{
  pkgs,
  ...
}:
{
  programs.git = {
    enable = true;
    package = pkgs.gitFull;

    settings = {
      user = {
        name = "tryy3";
        email = "github.com@compilethis.eu";
      };

      push = {
        default = "simple";
        autoSetupRemote = true;
      };
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
