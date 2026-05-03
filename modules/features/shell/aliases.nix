{ ... }:
let
  devDirectory = "$HOME/src";
  devNix = "${devDirectory}/nix";
in
{
  whichreal = ''function _whichreal(){ (alias "$1" >/dev/null 2>&1 && (alias "$1" | sed "s/.*=.\(.*\).../\1/" | xargs which)) || which "$1"; }; _whichreal'';

  #-------------Bat related------------
  cat = "bat --paging=never";
  diff = "batdiff";
  less = "bat --style=plain";
  rg = "rg -M300";

  #------------Navigation------------
  rst = "reset";
  doc = "cd $HOME/doc";
  edu = "cd $HOME/edu";
  wiki = "cd $HOME/sync/obsidian-vault-01/wiki";
  l = "eza -lah";
  la = "eza -lah";
  ldt = "eza -TD";
  ll = "eza -lh";
  ls = "eza";
  lsa = "eza -lah";
  tree = "eza -T";
  ".h" = "cd ~";
  cdr = "cd-gitroot";
  ".r" = "cd-gitroot";
  cdpr = "..; cd-gitroot";
  "..r" = "..; cd-gitroot";

  #------------compression------------
  unzip = "7z x";

  #------------ src navigation------------
  src = "cd ${devDirectory}";
  cab = "cd ${devDirectory}/abbot-wiki";
  cuc = "cd ${devDirectory}/unmoved-centre";
  ## nix
  cnc = "cd ${devNix}/nix-config";
  cns = "cd ${devNix}/nix-secrets";
  cnh = "cd ${devNix}/nixos-hardware";
  cnp = "cd ${devNix}/nixpkgs";
  cni = "cd ${devNix}/introdus";
  cnv = "cd ${devNix}/neovim";

  #-----------Nix commands----------------
  nfc = "nix flake check";
  ne = "nix instantiate --eval";
  nb = "nix build";
  ns = "nix shell";
  nrepl = ''
    nix repl --option experimental-features "flakes pipe-operators" \
    --expr 'rec { pkgs = import <nixpkgs>{}; lib = pkgs.lib; }'
  '';

  # prevent accidental killing of single characters
  pkill = "pkill -x";

  #-------------direnv---------------
  da = "direnv allow";
  dr = "direnv reload";

  #-------------justfiles---------------
  jr = "just rebuild";
  jrt = "just rebuild-trace";
  jl = "just --list";
  jup = "just update";
  jug = "just upgrade";

  #-------------Neovim---------------
  e = "nvim";
  vi = "nvim";
  vim = "nvim";

  #-------------Zed---------------
  zed = "zeditor";

  #-------------journalctl---------------
  jc = "journalctl";
  jcu = "journalctl --user";

  #-------------SSH---------------
  ssh = "TERM=xterm ssh";

  #-------------rmtrash---------------
  rrm = "/run/current-system/sw/bin/rm";
  rrmdir = "/run/current-system/sw/bin/rmdir";
  rm = "rmtrash";
  rmdir = "rmdirtrash";

  #-------------Git Goodness-------------
  # git aliases moved to introdus

  #-------------Podman------------------
  pod = "sudo podman -r";
}
