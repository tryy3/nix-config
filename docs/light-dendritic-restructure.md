# Light Dendritic Restructure Proposal

> **Date:** 2026-05-03
> **Status:** Research & proposal — not yet implemented
> **Goal:** Restructure nix-config for 2+ WSL machines with a single user ("tryy3"), feature-based modularity, and clear traceability.

---

## 1. Current Setup Analysis

### Architecture

The current config uses a **host/user-separated** pattern:

```
hosts/nixos/<hostname>/     → Host system config
hosts/common/core/          → Shared across all hosts
hosts/common/optional/      → Mix-and-match host-level configs
hosts/common/users/primary/ → User creation, HM wiring
home/<username>/<hostname>.nix → Per-host HM imports
home/<username>/common/     → Shared HM modules (core + optional)
```

### Pain Points

| Problem | Details |
|---|---|
| **Host/user separation** | To understand what `tryy3` gets on `nexer-wsl`, you must trace 7 hops: `flake.nix` → `hosts/nixos/nexer-wsl/` → `hosts/common/core/` → `hosts/common/users/primary/` → `home/tryy3/nexer-wsl.nix` → `home/tryy3/common/core/` → `home/tryy3/common/core/zsh/` |
| **Two user trees** | `home/tryy3-fw/` and `home/tryy3/` have nearly identical `common/core/default.nix` files (110 vs 105 lines). Any change to zsh, git, etc. must be duplicated. |
| **Implicit imports** | `scanPaths` auto-imports everything in module directories, making it hard to trace what's active on a given host. |
| **Manual host registration** | Hosts must be listed in `flake.nix`'s `nixosHosts` array — not auto-discovered. |
| **FIXME comments** | Template comments still present throughout, indicating incomplete customization. |

---

## 2. Research: Patterns in the Wild

### 2.1 The Dendritic Pattern

**Source:** [mightyiam/dendritic](https://github.com/mightyiam/dendritic) (440 stars)

The dendritic pattern is a **Nixpkgs module system usage pattern** that flips the configuration axis:

| Traditional | Dendritic |
|---|---|
| Organized by **WHERE** things apply (`hosts/nexer-wsl/`) | Organized by **WHAT** things do (`modules/zsh/`, `modules/neovim/`) |
| "What does machine X need?" → list imports | "Which features does this machine require?" → declare feature list |
| File type varies (NixOS modules, HM modules, plain attrsets) | **Every file is the same type** — a module of the top-level config |
| Values shared via `specialArgs` pass-through | Values shared via top-level `config` |

**How it works (simplified):**
- Every `.nix` file under `modules/` is a module of a top-level configuration
- Each module declares `config.flake.modules.nixos.<feature>` and `config.flake.modules.homeManager.<feature>`
- A host declares which features it wants by importing the relevant modules
- Commonly implemented with **flake-parts** + **import-tree** for auto-discovery

**Real-world examples:**
- [drupol/infra](https://github.com/drupol/infra) (125 stars) — Migrated from host-centric to dendritic. See [blog post](https://not-a-number.io/2025/refactoring-my-infrastructure-as-code-configurations/).
- [vic/vix](https://github.com/vic/vix) (80 stars) — Uses the `den` framework (a dendritic library). 13+ hosts across NixOS, macOS, WSL, Ubuntu.

**Trade-offs:**
- Pros: No duplication, every file type is known, automatic importing, file path independence, no `specialArgs` hell
- Cons: Steeper learning curve (flake-parts, `deferredModule`, `import-tree`), migration is time-consuming, overkill for 2 machines

### 2.2 Flake-Parts

**Source:** [flake.parts](https://flake.parts)

Flake-parts applies the NixOS module system to flake outputs. It introduces:
- `perSystem` — for cross-platform builds (packages, devShells, checks)
- `withSystem` — for accessing per-system attributes from top-level config
- `flake.modules` — for storing deferred modules

**Relevance:** Flake-parts is primarily useful when managing packages/devShells across multiple architectures. For a multi-host NixOS config where each host is independently built, it adds complexity without much benefit. The dendritic pattern *can* use flake-parts, but doesn't *require* it.

### 2.3 Other Patterns

| Pattern | Description | Verdict |
|---|---|---|
| **Host-centric** (current) | `hosts/<hostname>/` + `home/<username>/` separation | Works but confusing for multi-host |
| **Feature-flagged HM** | Single HM config with `enable` options per module | Good but requires writing proper modules with `options`/`config` |
| **Per-host user nesting** | `hosts/<hostname>/users/<username>/` | Simple but doesn't scale for shared features |
| **Digga/Devos** | Flake utility library for shell/home/host environments | **Deprecated** — not recommended |

---

## 3. Proposed Solution: Light Dendritic

### 3.1 Core Idea

Adopt the **mental model** of the dendritic pattern (features, not hosts) without the **framework overhead** (flake-parts, import-tree, `deferredModule`).

**Principles:**
1. **Organize by feature** — `modules/features/shell/`, `modules/features/neovim/`, etc.
2. **Each feature is a NixOS module** that configures both system and home-manager
3. **Hosts declare which features they want** via explicit `imports`
4. **Single user "tryy3"** everywhere — no more `tryy3-fw` vs `tryy3`
5. **Explicit imports over auto-discovery** — better traceability

### 3.2 Proposed Directory Structure

```
nix-config/
├── flake.nix                          # Simplified: inputs + host discovery
├── lib/
│   └── default.nix                    # Keep relativeToRoot
├── overlays/
│   └── default.nix                    # Keep as-is
├── pkgs/common/                       # Keep as-is (auto-discovered packages)
│
├── modules/
│   ├── base/                          # Always applied to every host
│   │   ├── default.nix                # Nix settings, overlays, nixpkgs config
│   │   ├── user.nix                   # User "tryy3" creation, SSH keys, shell
│   │   └── sops.nix                   # Secrets bootstrapping
│   │
│   ├── features/                      # Feature modules (the "dendritic" part)
│   │   ├── shell/                     # zsh, bash, starship, fzf, zoxide
│   │   │   ├── default.nix            # NixOS-level: programs.zsh.enable
│   │   │   ├── home.nix               # HM-level: zsh config, plugins, aliases
│   │   │   ├── aliases.nix
│   │   │   ├── plugins.nix
│   │   │   └── zshrc
│   │   ├── git/
│   │   │   └── home.nix
│   │   ├── fonts/
│   │   │   ├── default.nix            # NixOS: fonts.packages
│   │   │   └── home.nix               # HM: fontconfig
│   │   ├── ghostty/
│   │   │   └── home.nix
│   │   ├── direnv/
│   │   │   └── home.nix
│   │   ├── neovim/                    # Future: stable base neovim config
│   │   │   ├── default.nix
│   │   │   └── home.nix
│   │   ├── ssh/
│   │   │   └── home.nix
│   │   ├── wsl/                       # WSL-specific system config
│   │   │   └── default.nix
│   │   ├── desktop/                   # Wayland compositor + shell
│   │   │   ├── default.nix
│   │   │   ├── mango.nix
│   │   │   └── dms.nix
│   │   ├── audio/
│   │   │   └── default.nix
│   │   ├── browsers/
│   │   │   └── home.nix
│   │   ├── kubernetes/
│   │   │   └── default.nix
│   │   ├── tailscale/
│   │   │   └── default.nix
│   │   ├── podman/
│   │   │   └── default.nix
│   │   └── sops/
│   │       └── home.nix
│   │
│   └── hosts/                         # Host declarations (feature lists)
│       ├── nexer-wsl.nix              # "nexer-wsl wants: base + wsl + shell + ..."
│       └── fw-16.nix                  # "fw-16 wants: base + desktop + shell + ..."
│
├── hosts/                             # Hardware configs only
│   ├── nexer-wsl/
│   │   ├── default.nix                # hostSpec + WSL hardware settings
│   │   └── hermes.nix
│   └── fw-16/
│       ├── default.nix                # hostSpec + GPU + bootloader
│       └── hardware-configuration.nix
│
├── nixos-installer/                   # Keep as-is
└── docs/
```

### 3.3 What Gets Removed

| Old Path | Replaced By |
|---|---|
| `home/tryy3-fw/` | Consolidated into `modules/features/` |
| `home/tryy3/` | Consolidated into `modules/features/` |
| `hosts/common/core/` | `modules/base/` |
| `hosts/common/optional/` | `modules/features/` |
| `hosts/common/users/primary/` | `modules/base/user.nix` |
| `modules/common/` (auto-imported) | `modules/base/` (explicit) |
| `modules/home/` (auto-imported) | Feature modules' `home.nix` files |
| `modules/hosts/common/` | Merged into `modules/base/` |
| `modules/hosts/nixos/` | Merged into `modules/base/` |

### 3.4 Simplified flake.nix

```nix
{
  description = "tryy3's Nix Config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # ... other inputs (hardware, sops-nix, mango, dms, etc.) ...
    nix-secrets = {
      url = "git+ssh://git@github.com/tryy3/nix-secrets.git?ref=simple&shallow=1";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      lib = nixpkgs.lib.extend (self: super: {
        custom = import ./lib { inherit (nixpkgs) lib; };
      });

      # Add new hosts here
      nixosHosts = [ "nexer-wsl" ];
    in
    {
      overlays = import ./overlays { inherit inputs; };

      nixosConfigurations = builtins.listToAttrs (
        map (host: {
          name = host;
          value = lib.nixosSystem {
            specialArgs = { inherit inputs outputs lib; };
            modules = [ ./modules/hosts/${host}.nix ];
          };
        }) nixosHosts
      );

      packages = ...;   # Keep as-is
      formatter = ...;  # Keep as-is
      checks = ...;     # Keep as-is
      devShells = ...;  # Keep as-is
    };
}
```

---

## 4. Module Examples

### 4.1 Common Feature: `shell` (shared by all hosts)

This is the most important example — it shows how a feature bridges NixOS and Home Manager.

#### `modules/features/shell/default.nix` — NixOS-level

```nix
# modules/features/shell/default.nix
#
# NixOS-level shell configuration.
# Enables zsh system-wide, sets the user's default shell,
# and wires the Home Manager shell config.
{ config, lib, pkgs, ... }:
let
  hostSpec = config.hostSpec;
  username = hostSpec.username;
in
{
  # === NixOS system config ===

  # Enable zsh at the system level (required for login shell)
  programs.zsh.enable = true;

  # Enable git system-wide
  programs.git.enable = true;

  # Set the user's default shell
  users.users.${username}.shell = lib.mkDefault pkgs.zsh;

  # === Wire Home Manager config ===
  # The feature owns its HM config — no need for the host to wire it.
  home-manager.users.${username}.imports = [
    ./home.nix
  ];
}
```

#### `modules/features/shell/home.nix` — HM-level

```nix
# modules/features/shell/home.nix
#
# Home Manager shell configuration.
# All zsh, bash, starship, fzf, zoxide config lives here.
{ config, lib, pkgs, osConfig, ... }:
{
  # === Packages tied to shell ===
  home.packages = with pkgs; [
    rmtrash
    fzf
    fd
    ripgrep
  ];

  # === Zoxide ===
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    options = [ "--cmd cd" ];
  };

  # === FZF ===
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    defaultOptions = [ "--height 40%;" "--border" "--reverse" ];
  };

  # === Starship ===
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

  # === Zsh ===
  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    autocd = true;
    autosuggestion.enable = true;

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
      plugins = [ "git" "sudo" "extract" "command-not-found" ];
      extraConfig = ''
        COMPLETION_WAITING_DOTS="true"
      '';
    };

    shellAliases = import ./aliases.nix { inherit osConfig; };
  };
}
```

#### `modules/features/shell/aliases.nix`

```nix
# modules/features/shell/aliases.nix
{ osConfig, ... }:
let
  devDirectory = "$HOME/src";
  devNix = "${devDirectory}/nix";
in
{
  cat = "bat --paging=never";
  diff = "batdiff";
  ls = "eza";
  l = "eza -lah";
  ll = "eza -lh";
  e = "nvim";
  vi = "nvim";
  vim = "nvim";
  src = "cd ${devDirectory}";
  cnc = "cd ${devNix}/nix-config";
  cns = "cd ${devNix}/nix-secrets";
  jr = "just rebuild";
  jl = "just --list";
  jup = "just update";
  # ... more aliases ...
}
```

#### `modules/features/shell/plugins.nix`

```nix
# modules/features/shell/plugins.nix
{ pkgs }:
[
  {
    name = "zhooks";
    src = "${pkgs.zsh-zhooks}/share/zsh/zhooks";
  }
  {
    name = "zsh-vi-mode";
    src = "${pkgs.zsh-vi-mode}/share/zsh-vi-mode";
  }
  {
    name = "zsh-nix-shell";
    file = "nix-shell.plugin.zsh";
    src = pkgs.fetchFromGitHub {
      owner = "chisui";
      repo = "zsh-nix-shell";
      rev = "v0.8.0";
      sha256 = "1lzrn0n4fxfcgg65v0qhnj7wnybybqzs4adz7xsrkgmcsr0ii8b7";
    };
  }
  # ... more plugins ...
]
```

#### `modules/features/shell/zshrc`

```
# modules/features/shell/zshrc
unsetopt correct
setopt hist_ignore_all_dups
setopt hist_reduce_blanks
setopt inc_append_history
setopt auto_list
setopt auto_menu
zstyle ':completion:*' menu select
zstyle ':completion:*' group-name ""
zstyle ':completion:::::' completer _expand _complete _ignored _approximate

function git_smart_rebase() {
    GIT_STASH_MESSAGE="git_smart_rebase: $RANDOM"
    git stash push -m "$GIT_STASH_MESSAGE"
    git fetch && git rebase
    git stash list | (grep "${GIT_STASH_MESSAGE}" && git stash pop) || true
}
```

---

### 4.2 Common Feature: `git` (shared by all hosts)

A simpler feature — only HM config, no NixOS-level config needed.

#### `modules/features/git/home.nix`

```nix
# modules/features/git/home.nix
#
# Home Manager git configuration.
# Shared by all hosts — no NixOS-level config needed.
{ config, lib, pkgs, osConfig, ... }:
let
  hostSpec = osConfig.hostSpec;
in
{
  programs.git = {
    enable = true;
    userName = hostSpec.userFullName;
    userEmail = hostSpec.email;

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core.editor = "nvim";
    };

    ignores = [
      ".DS_Store"
      "*.swp"
      "*~"
      ".env"
      ".env.local"
      "result"
      "result-*"
    ];
  };
}
```

**Note:** This feature has no `default.nix` (NixOS-level) because git is already enabled system-wide by the `shell` feature. It only needs `home.nix`.

---

### 4.3 Common Feature: `fonts` (NixOS + HM)

Shows a feature that configures both system packages and user fontconfig.

#### `modules/features/fonts/default.nix`

```nix
# modules/features/fonts/default.nix
#
# NixOS-level font configuration.
# Installs font packages system-wide.
{ pkgs, ... }:
{
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.iosevka
    noto-fonts
    noto-fonts-emoji
  ];
}
```

#### `modules/features/fonts/home.nix`

```nix
# modules/features/fonts/home.nix
#
# Home Manager font configuration.
# Sets default fonts for applications.
{ ... }:
{
  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      monospace = [ "FiraCode Nerd Font Mono" ];
      sansSerif = [ "Noto Sans" ];
      serif = [ "Noto Serif" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
}
```

---

### 4.4 Host-Specific Feature: `wsl` (only for WSL machines)

Shows a feature that is only relevant to certain hosts.

#### `modules/features/wsl/default.nix`

```nix
# modules/features/wsl/default.nix
#
# WSL-specific system configuration.
# Only imported by WSL hosts.
{ pkgs, ... }:
{
  # Enable WSL integration
  wsl.enable = true;
  wsl.defaultUser = "tryy3";

  # Required for running pre-compiled non-Nix binaries
  # (e.g., VS Code remote server, downloaded binaries)
  programs.nix-ld.enable = true;

  # NetworkManager for WSL
  networking = {
    networkmanager.enable = true;
    enableIPv6 = false;
  };

  # WSL doesn't use traditional boot loaders
  boot.loader.systemd-boot.enable = false;
  boot.loader.grub.enable = false;
}
```

**Note:** This feature has no `home.nix` because WSL-specific config is purely system-level.

---

### 4.5 Host-Specific Feature: `desktop` (only for desktop/laptop machines)

Shows a feature with sub-modules for different compositors.

#### `modules/features/desktop/default.nix`

```nix
# modules/features/desktop/default.nix
#
# Base desktop configuration shared by all desktop hosts.
{ pkgs, ... }:
{
  # Enable dconf for GTK theming
  programs.dconf.enable = true;

  # Graphics support
  hardware.graphics.enable = true;

  # Power management (for laptops)
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
}
```

#### `modules/features/desktop/mango.nix`

```nix
# modules/features/desktop/mango.nix
#
# MangoWC Wayland compositor configuration.
{ config, lib, pkgs, inputs, ... }:
let
  hostSpec = config.hostSpec;
in
{
  imports = [
    inputs.mango.nixosModules.default
  ];

  # MangoWC system config
  programs.mango = {
    enable = true;
    # ... MangoWC settings ...
  };

  # Wire MangoWC HM config
  home-manager.users.${hostSpec.username}.imports = [
    inputs.mango.homeManagerModules.default
  ];
}
```

#### `modules/features/desktop/dms.nix`

```nix
# modules/features/desktop/dms.nix
#
# DankMaterialShell desktop shell configuration.
{ config, lib, pkgs, inputs, ... }:
let
  hostSpec = config.hostSpec;
in
{
  imports = [
    inputs.dms.nixosModules.default
  ];

  programs.dms = {
    enable = true;
    # ... DMS settings ...
  };
}
```

---

### 4.6 Base Module (replaces `hosts/common/core`)

#### `modules/base/default.nix`

```nix
# modules/base/default.nix
#
# Base configuration applied to ALL hosts.
# This replaces hosts/common/core/default.nix.
{ inputs, outputs, config, lib, pkgs, ... }:
let
  platform = "nixos";
  platformModules = "${platform}Modules";
in
{
  imports = [
    inputs.home-manager.${platformModules}.home-manager
    inputs.sops-nix.${platformModules}.sops
  ];

  # === Host spec defaults ===
  hostSpec = {
    username = "tryy3";
    handle = "tryy3";
    inherit (inputs.nix-secrets) domain email userFullName networking;
  };

  networking.hostName = config.hostSpec.hostName;

  # System-wide packages
  environment.systemPackages = [ pkgs.openssh pkgs.just pkgs.rsync ];

  # === Home Manager defaults ===
  home-manager.useGlobalPkgs = true;
  home-manager.backupFileExtension = "bk";

  # === Overlays ===
  nixpkgs = {
    overlays = [ outputs.overlays.default ];
    config.allowUnfree = true;
  };

  # === Nix settings ===
  nix = {
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    settings = {
      connect-timeout = 5;
      log-lines = 25;
      min-free = 128000000;
      max-free = 1000000000;
      trusted-users = [ "@wheel" ];
      auto-optimise-store = true;
      warn-dirty = false;
      allow-import-from-derivation = false;
      experimental-features = [ "nix-command" "flakes" ];
    };
  };
}
```

#### `modules/base/user.nix`

```nix
# modules/base/user.nix
#
# Primary user configuration.
# Replaces hosts/common/users/primary/default.nix + nixos.nix.
{ config, lib, pkgs, ... }:
let
  hostSpec = config.hostSpec;
  username = hostSpec.username;

  pubKeys = lib.filter (f: lib.hasSuffix ".pub" (toString f)) (
    lib.filesystem.listFilesRecursive ./keys
  );

  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;

  sopsHashedPasswordFile = lib.optionalString (
    !config.hostSpec.isMinimal
  ) config.sops.secrets."passwords/${username}".path;
in
{
  # === User creation ===
  users.users.${username} = {
    name = username;
    home = "/home/${username}";
    isNormalUser = true;
    shell = pkgs.zsh;
    hashedPasswordFile = sopsHashedPasswordFile;

    openssh.authorizedKeys.keys = lib.lists.forEach pubKeys (key: builtins.readFile key);

    extraGroups = lib.flatten [
      "wheel"
      (ifTheyExist [ "audio" "video" "docker" "git" "networkmanager" "scanner" "lp" ])
    ];
  };

  # === Root user (mirror primary user) ===
  users.users.root = {
    shell = pkgs.bash;
    hashedPasswordFile = config.users.users.${username}.hashedPasswordFile;
    hashedPassword = config.users.users.${username}.hashedPassword;
    openssh.authorizedKeys.keys = config.users.users.${username}.openssh.authorizedKeys.keys;
  };

  users.mutableUsers = false;

  # === SSH sockets directory ===
  systemd.tmpfiles.rules = [
    "d /home/${username}/.ssh 0750 ${username} ${config.users.users.${username}.group} -"
    "d /home/${username}/.ssh/sockets 0750 ${username} ${config.users.users.${username}.group} -"
  ];
}
```

---

### 4.7 Host Declarations (Feature Lists)

This is where the dendritic pattern shines — each host declares its features explicitly.

#### `modules/hosts/nexer-wsl.nix`

```nix
# modules/hosts/nexer-wsl.nix
#
# nexer-wsl host configuration.
# Declares which features this host needs.
{ lib, inputs, ... }:
{
  imports = [
    # === Base (always needed) ===
    ../base

    # === Shared features ===
    ../features/shell
    ../features/git
    ../features/fonts
    ../features/ghostty
    ../features/direnv
    ../features/ssh

    # === WSL-specific features ===
    ../features/wsl
    ../features/kubernetes
    ../features/sops

    # === Hardware + host-specific config ===
    ../../hosts/nexer-wsl
  ];

  # Host specification overrides
  hostSpec = {
    hostName = "nexer-wsl";
    nixConfigPath = "/home/tryy3/nix-config";
  };
}
```

#### `modules/hosts/fw-16.nix`

```nix
# modules/hosts/fw-16.nix
#
# fw-16 host configuration.
# Declares which features this host needs.
{ lib, inputs, ... }:
{
  imports = [
    # === Base ===
    ../base

    # === Shared features ===
    ../features/shell
    ../features/git
    ../features/fonts
    ../features/ghostty
    ../features/direnv
    ../features/ssh

    # === Desktop features ===
    ../features/desktop
    ../features/audio
    ../features/browsers
    ../features/sops

    # === Network features ===
    ../features/tailscale
    ../features/podman

    # === Hardware + host-specific config ===
    ../../hosts/fw-16
  ];

  hostSpec = {
    hostName = "fw-16";
  };
}
```

---

### 4.8 Hardware Configs (Stay in `hosts/`)

Hardware-specific config stays separate from features.

#### `hosts/nexer-wsl/default.nix`

```nix
# hosts/nexer-wsl/default.nix
#
# nexer-wsl hardware and host-specific configuration.
# No feature logic here — just hardware and hostSpec.
{ inputs, lib, ... }:
{
  imports = [
    inputs.nixos-wsl.nixosModules.default
    inputs.hermes-agent.nixosModules.default
    ./hermes.nix
  ];

  # WSL-specific hardware settings
  wsl.enable = true;
  wsl.defaultUser = "tryy3";
  programs.nix-ld.enable = true;

  system.stateVersion = "24.11";
}
```

#### `hosts/fw-16/default.nix`

```nix
# hosts/fw-16/default.nix
#
# fw-16 hardware and host-specific configuration.
{ lib, inputs, config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    inputs.hardware.nixosModules.framework-16-amd-ai-300-series-nvidia
    inputs.nix-index-database.nixosModules.default
  ];

  # Hardware-specific settings
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 3;

  boot.initrd.systemd.enable = true;
  boot.kernelParams = [ "amdgpu.abmlevel=0" ];
  boot.kernelPackages = pkgs.linuxPackages_7_0;

  console.keyMap = "sv-latin1";

  hardware.graphics.enable = true;
  hardware.nvidia.prime = {
    amdgpuBusId = "PCI:194:0:0";
    nvidiaBusId = "PCI:193:0:0";
  };

  # WiFi profile (uses sops secrets)
  sops.secrets."wifi/home-psk" = {
    mode = "0400";
    owner = config.users.users.${config.hostSpec.username}.name;
    group = config.users.users.${config.hostSpec.username}.group;
  };

  sops.templates."networkmanager.env".content = ''
    HOME_PSK=${config.sops.placeholder."wifi/home-psk"}
  '';

  networking.networkmanager.enable = true;
  networking.networkmanager.ensureProfiles = {
    environmentFiles = [ config.sops.templates."networkmanager.env".path ];
    profiles.home = {
      connection = { id = "home"; type = "wifi"; autoconnect = true; };
      wifi = { ssid = "Kaktus Plantan"; mode = "infrastructure"; };
      wifi-security = { key-mgmt = "wpa-psk"; psk = "$HOME_PSK"; };
      ipv4.method = "auto";
      ipv6.method = "auto";
    };
  };

  system.stateVersion = "24.11";

  programs.nix-index-database = {
    enable = true;
    comma.enable = true;
  };
}
```

---

## 5. Host-Specific Overrides

Sometimes a feature needs different behavior per host. There are two approaches:

### 5.1 Conditional in the Feature Module

```nix
# modules/features/shell/aliases.nix
{ osConfig, lib, ... }:
let
  hostName = osConfig.hostSpec.hostName;
in
{
  # Shared aliases
  ls = "eza";

  # WSL-specific alias
  wsl-open = lib.mkIf (hostName == "nexer-wsl") "explorer.exe .";

  # Desktop-specific alias
  screenshot = lib.mkIf (hostName == "fw-16") "grim -g \"$(slurp)\"";
}
```

### 5.2 Host-Level Override

```nix
# modules/hosts/nexer-wsl.nix
{ lib, inputs, ... }:
{
  imports = [
    ../base
    ../features/shell
    # ...
  ];

  hostSpec = {
    hostName = "nexer-wsl";
  };

  # Override shell aliases just for this host
  home-manager.users.tryy3.programs.zsh.shellAliases = {
    wsl-open = "explorer.exe .";
    linux-only = lib.mkForce "";  # remove an alias from the shared config
  };
}
```

### 5.3 Using `hostSpec` Flags

Define flags in `hostSpec` and use them in feature modules:

```nix
# modules/hosts/nexer-wsl.nix
hostSpec = {
  hostName = "nexer-wsl";
  isWsl = true;
  isMinimal = false;
};

# modules/features/shell/default.nix
{ config, ... }:
let
  hostSpec = config.hostSpec;
in
{
  # Only enable certain plugins on non-WSL hosts
  home-manager.users.${hostSpec.username}.programs.zsh.plugins =
    lib.optionals (!hostSpec.isWsl) [
      { name = "zsh-term-title"; src = "..."; }
    ];
}
```

---

## 5.4 Feature Variants (Stable vs Experimental)

A common scenario: two hosts both want the "desktop" feature, but one should be stable and conservative while the other is experimental and bleeding-edge. The same applies to browsers, editors, or any feature where you want to test new configurations on one machine before rolling them out to others.

### The Problem

You want both hosts to share a **common base** (same window manager, same keybindings, same theme) but differ in **specific details** (stable packages vs unstable, conservative settings vs experimental ones).

### The Solution: Sub-Folder Variants with Shared Common

Your intuition is correct — use sub-folders under the feature directory. The pattern is:

```
modules/features/desktop/
├── common.nix              # Shared base config (WM, theme, keybindings)
├── stable/
│   └── default.nix         # Imports common.nix + stable-specific overrides
└── experimental/
    └── default.nix         # Imports common.nix + experimental-specific overrides
```

The host explicitly chooses which variant to import:

```nix
# modules/hosts/fw-16.nix (stable machine)
imports = [
  ../features/desktop/stable
  ../features/browser/stable
];

# modules/hosts/experiment-laptop.nix (experimental machine)
imports = [
  ../features/desktop/experimental
  ../features/browser/experimental
];
```

### Concrete Example: Desktop Feature

#### `modules/features/desktop/common.nix` — Shared Base

```nix
# modules/features/desktop/common.nix
#
# Shared desktop configuration — the foundation both variants build on.
# Window manager, theme, keybindings, display settings.
{ config, lib, pkgs, ... }:
let
  hostSpec = config.hostSpec;
in
{
  # === System-level ===
  programs.dconf.enable = true;
  hardware.graphics.enable = true;
  services.power-profiles-daemon.enable = true;

  # === Home Manager — shared desktop config ===
  home-manager.users.${hostSpec.username}.imports = [
    ./home-common.nix
  ];
}
```

#### `modules/features/desktop/home-common.nix` — Shared HM Config

```nix
# modules/features/desktop/home-common.nix
#
# Shared Home Manager desktop config — used by BOTH variants.
{ config, lib, pkgs, ... }:
{
  # Theme (shared)
  gtk = {
    enable = true;
    theme.name = "Catppuccin-Mocha";
    iconTheme.name = "Papirus-Dark";
  };

  # Keybindings (shared — defined in WM-agnostic way or Mango-specific)
  # These are the bindings you want identical across all machines.

  # Display settings (shared)
  wayland.windowManager.mango.settings = {
    # Shared keybindings, rules, output config
    binds = {
      "MOD+Return" = "ghostty";
      "MOD+q" = "close";
      "MOD+d" = "dms-launcher";
    };
  };
}
```

#### `modules/features/desktop/stable/default.nix` — Stable Variant

```nix
# modules/features/desktop/stable/default.nix
#
# Stable desktop variant.
# Uses stable packages, conservative settings, well-tested configs.
{ config, lib, pkgs, ... }:
let
  hostSpec = config.hostSpec;
in
{
  # Import the shared common config
  imports = [ ../common.nix ];

  # === Stable-specific overrides ===

  # Use stable nixpkgs for desktop packages
  home-manager.users.${hostSpec.username} = {
    # Override packages to use stable channel
    home.packages = with pkgs.stable; [
      firefox
      vlc
    ];

    # Conservative MangoWC settings — no experimental features
    wayland.windowManager.mango.settings = {
      experimental = {
        enable = false;
        features = [ ];
      };
    };
  };
}
```

#### `modules/features/desktop/experimental/default.nix` — Experimental Variant

```nix
# modules/features/desktop/experimental/default.nix
#
# Experimental desktop variant.
# Uses unstable packages, bleeding-edge features, new configs to test.
{ config, lib, pkgs, ... }:
let
  hostSpec = config.hostSpec;
in
{
  # Import the shared common config
  imports = [ ../common.nix ];

  # === Experimental-specific overrides ===

  # Use unstable nixpkgs for desktop packages
  home-manager.users.${hostSpec.username} = {
    home.packages = with pkgs.unstable; [
      firefox-wayland
      mpv
    ];

    # Enable experimental MangoWC features
    wayland.windowManager.mango.settings = {
      experimental = {
        enable = true;
        features = [ "new-renderer" "gpu-accelerated-blur" ];
      };

      # Try new keybinding scheme
      binds = {
        "MOD+Shift+d" = "dms-launcher";  # new binding to test
      };
    };
  };
}
```

### How the Merge Works

When Nix evaluates the experimental variant, it:

1. Imports `../common.nix` → sets base WM config, shared keybindings, theme
2. Applies experimental overrides → replaces/adds specific attributes

Because Nix modules use **recursive attribute set merging**, the experimental variant's `wayland.windowManager.mango.settings.binds` will **merge** with the common one, not replace it entirely. New bindings are added, existing ones are overridden.

If you need a **complete replacement** instead of a merge, use `lib.mkForce`:

```nix
wayland.windowManager.mango.settings.binds = lib.mkForce {
  "MOD+Return" = "alacritty";  # completely replace all bindings
};
```

### Concrete Example: Browser Feature

Same pattern applies to any feature:

```
modules/features/browser/
├── common.nix              # Shared: bookmarks, extensions list, profile settings
├── stable/
│   └── default.nix         # Firefox stable, conservative settings
└── experimental/
    └── default.nix         # Firefox nightly or Zen browser, experimental flags
```

```nix
# modules/features/browser/common.nix
{ config, lib, pkgs, ... }:
let
  hostSpec = config.hostSpec;
in
{
  home-manager.users.${hostSpec.username} = {
    # Shared bookmarks
    xdg.configFile."browser/bookmarks.html".source = ./bookmarks.html;

    # Shared extensions (by ID — works across Firefox versions)
    programs.firefox.profiles.default.extensions = {
      "uBlock0@raymondhill.net" = { };
      "firefox@privacy-badger.eff.org" = { };
    };
  };
}
```

```nix
# modules/features/browser/stable/default.nix
{ config, lib, pkgs, ... }:
let
  hostSpec = config.hostSpec;
in
{
  imports = [ ../common.nix ];

  home-manager.users.${hostSpec.username} = {
    programs.firefox = {
      enable = true;
      package = pkgs.stable.firefox;

      profiles.default.settings = {
        "browser.startup.homepage" = "https://nixos.org";
        # Conservative: no experimental features
      };
    };
  };
}
```

```nix
# modules/features/browser/experimental/default.nix
{ config, lib, pkgs, ... }:
let
  hostSpec = config.hostSpec;
in
{
  imports = [ ../common.nix ];

  home-manager.users.${hostSpec.username} = {
    programs.firefox = {
      enable = true;
      package = pkgs.unstable.firefox;  # or zen-browser

      profiles.default.settings = {
        "browser.startup.homepage" = "https://nixos.org";
        # Experimental: try new features
        "gfx.webrender.all" = true;
        "layout.css.grid-template-masonry-value.enabled" = true;
      };
    };
  };
}
```

### When to Use Variants vs Host-Level Overrides

| Scenario | Recommended Approach | Why |
|---|---|---|
| **Small tweak** (1-2 settings differ) | Host-level override (section 5.2) | Less structure needed, just override in the host file |
| **Significant divergence** (different packages, experimental features) | Feature variant (this section) | Keeps the divergence organized and reusable |
| **3+ hosts with same variant** | Feature variant | The variant becomes a reusable "profile" |
| **Temporary experiment** (test for a week, then revert) | Host-level override | Don't create a variant for something you'll delete soon |
| **Long-term split** (stable vs experimental as a permanent setup) | Feature variant | The variant documents the intentional split |

### Decision Flowchart

```
Do two hosts need the same feature but different configs?
│
├─ Differences are minor (1-2 settings)?
│  └─ YES → Use host-level override (section 5.2)
│  └─ NO ↓
│
├─ Will this split be temporary (< 1 week)?
│  └─ YES → Use host-level override
│  └─ NO ↓
│
├─ Will 3+ hosts share the same variant?
│  └─ YES → Create feature variant (stable/experimental/etc.)
│  └─ NO ↓
│
└─ Is the divergence significant (different packages, major config changes)?
   └─ YES → Create feature variant
   └─ NO → Use host-level override
```

### Naming Conventions

| Convention | Example | When to Use |
|---|---|---|
| **stable / experimental** | `desktop/stable/`, `desktop/experimental/` | General purpose — one is conservative, one tests new things |
| **stable / unstable** | `browser/stable/`, `browser/unstable/` | When the difference is specifically about nixpkgs channel |
| **v1 / v2** | `neovim/v1/`, `neovim/v2/` | When migrating between config versions (temporary) |
| **minimal / full** | `desktop/minimal/`, `desktop/full/` | When one host needs fewer features (e.g., server vs desktop) |
| **host-specific** | `desktop/fw-16/`, `desktop/experiment-laptop/` | When the config is truly unique to one host (rare — prefer host-level override) |

**Recommendation:** Start with `stable` / `experimental`. It's the most descriptive and matches your mental model.

---

## 6. Adding a New WSL Machine

With the light dendritic setup, adding a new machine is straightforward:

### Step 1: Create hardware config

```bash
mkdir -p hosts/new-wsl
# Copy hardware-configuration.nix from the machine
```

```nix
# hosts/new-wsl/default.nix
{ inputs, ... }:
{
  imports = [
    inputs.nixos-wsl.nixosModules.default
  ];

  wsl.enable = true;
  wsl.defaultUser = "tryy3";
  programs.nix-ld.enable = true;
  system.stateVersion = "24.11";
}
```

### Step 2: Create host declaration with feature list

```nix
# modules/hosts/new-wsl.nix
{ lib, inputs, ... }:
{
  imports = [
    ../base
    ../features/shell
    ../features/git
    ../features/fonts
    ../features/ghostty
    ../features/direnv
    ../features/ssh
    ../features/wsl
    ../features/sops
    ../../hosts/new-wsl
  ];

  hostSpec = {
    hostName = "new-wsl";
    nixConfigPath = "/home/tryy3/nix-config";
  };
}
```

### Step 3: Register in flake.nix

```nix
nixosHosts = [ "nexer-wsl" "new-wsl" ];
```

### Step 4: Build

```bash
sudo nixos-rebuild switch --flake .#new-wsl
```

**That's it.** No new user directories, no copying HM configs, no `scanPaths` updates.

---

## 7. Migration Path

The migration is split into two parts:

- **Part A: Username consolidation** (`tryy3-fw` → `tryy3`) — do this first, on the current structure
- **Part B: Light dendritic restructure** — do this after the username is settled

---

### Part A: Username Consolidation (tryy3-fw → tryy3)

This is a **3-step, zero-downtime migration**. We add `tryy3` alongside `tryy3-fw` on fw-16, verify everything works, then remove `tryy3-fw`. This avoids the problem of Nix deleting the user and home directory in one go.

#### Step A1: Add `tryy3` alongside `tryy3-fw` on fw-16

**Goal:** Both users active on fw-16 with identical configs. `tryy3-fw` remains the primary login user.

**New file: `home/tryy3/fw-16.nix`**

```nix
# home/tryy3/fw-16.nix
#
# fw-16 home-manager config for user "tryy3".
# During migration, this mirrors tryy3-fw's config exactly.
# Sops is intentionally NOT imported — the age key is only
# bootstrapped for the primary user (tryy3-fw).
{ ... }:
{
  imports = [
    # Reuse tryy3-fw's common core config — both users share the same modules
    ../tryy3-fw/common/core

    # fw-16 specific optional features
    ../tryy3-fw/common/optional/browsers
    ../tryy3-fw/common/optional/desktops
    ../tryy3-fw/common/optional/mango.nix
    ../tryy3-fw/common/optional/dank-material-shell.nix
    ../tryy3-fw/common/optional/zed.nix

    # NOTE: sops.nix intentionally omitted — age key not bootstrapped for tryy3 yet
    # Will be added back in Step A3 after tryy3-fw is removed
  ];
}
```

**Modified file: `hosts/nixos/fw-16/default.nix`**

Add this block at the end (inside the main `{ }`):

```nix
  #
  # ========== Second user: tryy3 (migration from tryy3-fw) ==========
  # Remove this entire block after Step A3.

  users.users.tryy3 = {
    isNormalUser = true;
    shell = pkgs.zsh;
    initialPassword = "changeme";  # Change after first login with `passwd`
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
  };

  home-manager.users.tryy3 = {
    imports = [ (lib.custom.relativeToRoot "home/tryy3/fw-16.nix") ];
    home.username = "tryy3";
    home.homeDirectory = "/home/tryy3";
  };
```

**Why this works:**

| Concern | How it's handled |
|---|---|
| Same HM config | `home/tryy3/fw-16.nix` imports `../tryy3-fw/common/` directly — zero duplication |
| Username override | `home.username = "tryy3"` overrides the `lib.mkDefault` from `common/core/default.nix` |
| Password | `initialPassword = "changeme"` — no sops changes needed |
| Sops age key | Intentionally skipped for `tryy3` during migration. `tryy3-fw` still gets its age key normally. |
| No conflict | `hosts/common/users/primary/` wires `home-manager.users.tryy3-fw`. We add `home-manager.users.tryy3` separately. |

**After Step A1:** Run `just rebuild`. This creates the `tryy3` user while keeping `tryy3-fw` untouched.

#### Step A2: Verify and Copy Non-Declarative Files

```bash
# Reboot and login as "tryy3" with password "changeme"
passwd  # Change password immediately
```

Copy files that Nix doesn't manage:

```bash
# Browser profiles (Firefox)
cp -a /home/tryy3-fw/.mozilla/firefox/ /home/tryy3/.mozilla/

# Browser profiles (Zen browser, if used)
cp -a /home/tryy3-fw/.zen/ /home/tryy3/.zen/ 2>/dev/null || true

# SSH keys (if any not managed by Nix)
cp -a /home/tryy3-fw/.ssh/ /home/tryy3/.ssh/ 2>/dev/null || true

# GPG keys
cp -a /home/tryy3-fw/.gnupg/ /home/tryy3/.gnupg/ 2>/dev/null || true

# Local bin scripts
cp -a /home/tryy3-fw/.local/bin/ /home/tryy3/.local/bin/ 2>/dev/null || true

# Fix ownership
sudo chown -R tryy3:tryy3 /home/tryy3/
```

Verify:
- Open Firefox/Zen — check history, bookmarks, extensions
- Open Ghostty — check config
- Run `jr` (just rebuild) — make sure the flake works from the new user
- Check MangoWC/DMS looks correct
- Test SSH, git, etc.

#### Step A3: Remove `tryy3-fw`

**1. Update `hosts/nixos/fw-16/default.nix`:**

Remove the second user block from Step A1, and remove the username override:

```nix
  hostSpec = {
    hostName = "fw-16";
    # REMOVE this line: username = lib.mkForce "tryy3-fw";
    # The default "tryy3" from hosts/common/core will now apply
  };
```

**2. Copy fw-16's common config to `tryy3`:**

```bash
# Backup tryy3's existing common (nexer-wsl might need it)
cp -r home/tryy3/common home/tryy3/common.bak

# Copy fw-16's common to tryy3 (overwrites)
cp -r home/tryy3-fw/common/* home/tryy3/common/
```

**3. Update `home/tryy3/fw-16.nix`** — switch to local imports and add sops back:

```nix
{ ... }:
{
  imports = [
    ./common/core
    ./common/optional/browsers
    ./common/optional/desktops
    ./common/optional/mango.nix
    ./common/optional/dank-material-shell.nix
    ./common/optional/zed.nix
    ./common/optional/sops.nix  # Now added back — age key will be bootstrapped
  ];
}
```

**4. Clean up:**

```bash
rm -rf home/tryy3-fw/
```

**5. Rebuild:**

```bash
just rebuild
```

This will:
- Remove `tryy3-fw` user (because `users.mutableUsers = false`)
- Set `tryy3` as the primary user
- Wire HM for `tryy3` via the normal `hosts/common/users/primary/` path
- Bootstrap sops age key for `tryy3`

**6. Final cleanup:**

```bash
sudo rm -rf /home/tryy3-fw
```

#### Risks and Mitigations

| Risk | Mitigation |
|---|---|
| `tryy3-fw` home deleted on rebuild | Won't happen in Step A1 — `tryy3-fw` is still primary. Only deleted in Step A3 after verification. |
| Browser history lost | Copied manually in Step A2. Nix doesn't manage browser profiles. |
| Sops not working for `tryy3` | Intentionally skipped in Step A1. Added back in Step A3 when `tryy3` becomes primary. |
| Need to go back | In Step A1, `tryy3-fw` is untouched. Don't proceed to A3 until confident. |

#### What About nexer-wsl?

The `tryy3` user on nexer-wsl is **unaffected** by this migration:

- `home/tryy3/nexer-wsl.nix` imports from `tryy3`'s own `common/` directory
- After Step A3, `home/tryy3/common/` will have the fw-16 version
- If nexer-wsl needs different config, it imports different subsets of `common/optional/` — they can diverge freely

---

### Part B: Light Dendritic Restructure

After the username is consolidated, proceed with the feature-based restructure.

#### Phase B1: Extract Shared Features (Medium Risk)

- Create `modules/features/shell/` from `home/tryy3/common/core/zsh/` + related files
- Create `modules/features/git/` from `home/tryy3/common/core/git.nix`
- Create `modules/features/fonts/` from `home/tryy3/common/core/fonts.nix`
- Test with one host first (nexer-wsl, since it has fewer features)

#### Phase B2: Restructure Hosts (Medium Risk)

- Create `modules/base/` from `hosts/common/core/` + `hosts/common/users/primary/`
- Create `modules/hosts/nexer-wsl.nix` and `modules/hosts/fw-16.nix`
- Move hardware-only config to `hosts/`
- Test both hosts

#### Phase B3: Clean Up (Low Risk)

- Remove old directories: `hosts/common/`, `home/tryy3/`
- Remove `scanPaths` from `modules/common/default.nix`, `modules/home/default.nix`, etc.
- Update flake.nix to point to new module paths
- Run `nix flake check --impure --keep-going --show-trace`

---

## 8. Comparison: Before vs After

### Traceability: "What zsh config does nexer-wsl get?"

| Before | After |
|---|---|
| 1. `flake.nix` → `hosts/nixos/nexer-wsl/` | 1. `modules/hosts/nexer-wsl.nix` → see `../features/shell` |
| 2. → `hosts/common/core/` (imports HM + users) | 2. `modules/features/shell/default.nix` → see `./home.nix` |
| 3. → `hosts/common/users/primary/` (enables zsh) | 3. `modules/features/shell/home.nix` → **done** |
| 4. → `home/tryy3/nexer-wsl.nix` (imports common/core) | |
| 5. → `home/tryy3/common/core/` (scanPaths) | |
| 6. → `home/tryy3/common/core/zsh/default.nix` | |
| **7 hops** | **3 hops** |

### Duplication: Zsh config

| Before | After |
|---|---|
| `home/tryy3/common/core/zsh/` (94 lines) | `modules/features/shell/` (shared by all hosts) |
| `home/tryy3-fw/common/core/zsh/` (94 lines) | **1 copy, 0 duplication** |
| **188 lines total** | **~94 lines total** |

### Adding a new feature (e.g., neovim)

| Before | After |
|---|---|
| 1. Create `home/tryy3/common/core/neovim.nix` | 1. Create `modules/features/neovim/default.nix` + `home.nix` |
| 2. Create `home/tryy3-fw/common/core/neovim.nix` | 2. Add `../features/neovim` to each host's imports |
| 3. Add to `home/tryy3/nexer-wsl.nix` imports | |
| 4. Add to `home/tryy3-fw/fw-16.nix` imports | |
| **4 steps, 2 files to duplicate** | **2 steps, 1 file** |

---

## 9. What About `scanPaths`?

In the light dendritic approach, **`scanPaths` is dropped** in favor of explicit imports.

**Why:**
- The dendritic pattern's benefit of "every file type is known" is undermined by auto-import magic
- Explicit imports mean you can grep for a feature and see exactly which hosts use it
- Adding a new feature to a host is one line in the host's import list

**Trade-off:** Slightly more typing when adding a feature to a host, but vastly better traceability.

If you really want auto-import for features within a host, you could keep a lightweight version:

```nix
# modules/features/default.nix
{ lib, ... }:
let
  featureDirs = lib.attrNames (builtins.readDir ./.);
  featureModules = builtins.map (name: ./${name}) featureDirs;
in
{
  imports = featureModules;
}
```

But then **every feature is enabled on every host**, which defeats the purpose of feature selection.

---

## 10. Key Takeaways

1. **The dendritic pattern is relevant** but full flake-parts + import-tree is overkill for 2 machines
2. **Light dendritic** gives you the mental model benefits (features, not hosts) without the framework overhead
3. **Single user "tryy3"** eliminates the biggest source of duplication and confusion
4. **Explicit imports** over `scanPaths` for better traceability
5. **Migration can be incremental** — start with username consolidation, then extract features one by one
6. **Hardware config stays separate** from features — `hosts/` is for hardware, `modules/features/` is for functionality
