# AGENTS.md

## ⛔ CRITICAL: NEVER AUTO-BUILD ⛔

**NEVER run `just rebuild`, `just rebuild-trace`, `just rebuild-full`, `just rebuild-update`, `nixos-rebuild`, `nh os switch`, or any other command that builds and/or switches the system configuration.**

This is critical for two reasons:
1. **Security** — a build/switch applies changes to a running system. An incorrect config can lock you out, expose secrets, or break networking.
2. **Privilege** — these commands occasionally require `sudo`, which will hang or fail in an agent context.

If you determine that a build or switch is needed, **stop and ask the user to run the command themselves.** You may prepare the changes, verify them with `just check` or `nix fmt`, but the final build/switch step must always be user-initiated.

## What This Repo Is

A flake-based NixOS configuration using the **light dendritic pattern**. Manages multiple hosts (`fw-16`, `nexer-wsl`) with a single user (`tryy3`), feature-based modularity, and explicit imports for full traceability.

## Key Commands

All commands assume you're in the repo root with `direnv allow` already run.

| Command | Purpose |
|---|---|
| `just rebuild` | Build and switch to current config (uses `nh os switch` or falls back to `nixos-rebuild`) |
| `just rebuild-trace` | Rebuild with `--show-trace` for debugging |
| `just rebuild-full` | Rebuild then run `just check` |
| `just rebuild-update` | Update all flake inputs then rebuild |
| `just check` | Run `nix flake check --impure --keep-going --show-trace` on both main config and nixos-installer |
| `just update` | Update `flake.lock` without rebuilding |
| `just diff` | `git diff` excluding `flake.lock` |
| `nix fmt` | Format all `.nix` files with nixfmt-rfc-style |
| `just update-nix-secrets` | Fetch/rebase `../nix-secrets` and update its flake input |

Tests run via `nix flake check` (bats tests in `tests/`).

## Architecture

### Design Philosophy: Light Dendritic

The config follows a **feature-based** (dendritic) pattern rather than a host-centric one:

| Traditional | This Config |
|---|---|
| Organized by **WHERE** things apply (`hosts/<hostname>/`) | Organized by **WHAT** things do (`modules/features/shell/`, `modules/features/desktop/`) |
| "What does machine X need?" → list imports | "Which features does this machine require?" → declare feature list |
| Values shared via `specialArgs` pass-through | Values shared via top-level `config` and `hostSpec` |
| Auto-discovery via `scanPaths` | **Explicit imports** for full traceability |

### Directory Layout

```
nix-config/
├── flake.nix                          # Inputs + host registration (nixosHosts array)
├── lib/default.nix                    # Custom lib functions (relativeToRoot, scanPaths)
├── overlays/default.nix               # Package overlays (stable, unstable, custom pkgs)
├── pkgs/common/                       # Custom packages (auto-discovered)
│
├── modules/
│   ├── base/                          # Always applied to every host
│   │   ├── default.nix                # Nix settings, overlays, HM defaults, NixOS base
│   │   ├── home.nix                   # Core HM config (packages, env vars, gpg)
│   │   ├── user.nix                   # User "tryy3" creation, SSH keys, groups
│   │   ├── sops.nix                   # System-level sops/age key bootstrapping
│   │   └── keys/                      # SSH public keys for authorized_keys
│   │
│   ├── features/                      # Feature modules (the "dendritic" part)
│   │   ├── host-spec.nix              # hostSpec option definitions (shared by all)
│   │   ├── shell/                     # zsh, starship, fzf, zoxide
│   │   │   ├── default.nix            # NixOS-level + HM wiring
│   │   │   ├── home.nix               # HM-level config
│   │   │   ├── aliases.nix
│   │   │   ├── plugins.nix
│   │   │   └── zshrc
│   │   ├── git/
│   │   ├── fonts/
│   │   ├── ghostty/
│   │   ├── direnv/
│   │   ├── bat/
│   │   ├── ssh/
│   │   ├── sops/
│   │   ├── desktop/                   # Wayland compositor + audio + GPU
│   │   │   ├── default.nix
│   │   │   ├── home.nix
│   │   │   ├── mango.nix
│   │   │   ├── dms.nix
│   │   │   ├── greeter.nix
│   │   │   ├── gtk.nix
│   │   │   └── playerctl.nix
│   │   ├── browsers/                  # Firefox, Zen, Chromium, Vesktop
│   │   ├── zed/
│   │   ├── openssh/
│   │   ├── podman/
│   │   ├── tailscale/
│   │   └── kubernetes/
│   │
│   └── hosts/                         # Host declarations (feature lists)
│       ├── fw-16.nix                  # "fw-16 wants: base + desktop + shell + ..."
│       └── nexer-wsl.nix              # "nexer-wsl wants: base + shell + ..."
│
├── hosts/                             # Hardware configs only (no feature logic)
│   └── nixos/
│       ├── fw-16/
│       │   ├── default.nix            # GPU, bootloader, WiFi, kernel params
│       │   └── hardware-configuration.nix
│       └── nexer-wsl/
│           ├── default.nix            # WSL enable, nix-ld, stateVersion
│           └── hermes.nix
│
├── home/tryy3/                        # Host-specific HM overrides (usually empty)
│   ├── fw-16.nix
│   └── nexer-wsl.nix
│
├── nixos-installer/                   # Separate flake for remote NixOS installation
└── docs/
```

### Conventions

- **`lib.custom.relativeToRoot`** — References files from repo root (e.g., `"hosts/common/core"`). Equivalent to `lib.path.append ../.` applied to the string.
- **`hostSpec`** — Custom option module (`modules/features/host-spec.nix`) that declares host metadata (username, hostname, email, isMinimal, isWork, etc.). Set per-host in `modules/hosts/<hostname>.nix`, consumed everywhere via `config.hostSpec`.
- **Feature module structure** — Each feature directory contains:
  - `default.nix` — NixOS-level config + HM wiring (`home-manager.users.${username}.imports = [ ./home.nix ]`)
  - `home.nix` — Home Manager-level config (optional, only if the feature needs user-level config)
  - Additional `.nix` files — Sub-modules or data files (aliases, plugins, etc.)
- **Explicit imports** — No `scanPaths` auto-discovery for modules. Every feature is explicitly imported by each host that needs it.
- **`pkgs.stable` / `pkgs.unstable`** — Available via overlays. Use `pkgs.stable.<pkg>` or `pkgs.unstable.<pkg>` to pin specific packages.

### How Hosts Are Wired

1. `flake.nix` lists hosts in the `nixosHosts` array (see `nixosHosts` variable).
2. Each host entry points to `modules/hosts/<hostname>.nix` — the host's feature declaration file.
3. The host declaration file explicitly imports:
   - `../base` — always applied (Nix settings, user creation, sops, core HM)
   - Feature modules (e.g., `../features/shell`, `../features/git`)
   - Hardware config (`../../hosts/nixos/<hostname>`)
4. `modules/base/default.nix` imports `host-spec.nix`, `user.nix`, `sops.nix`, and wires Home Manager.
5. `modules/base/user.nix` creates the user and wires `modules/base/home.nix` as the base HM config.
6. Each feature module wires its own HM config via `home-manager.users.${username}.imports`.

## Secrets (sops-nix)

- Secrets live in a **separate repo** at `../nix-secrets` (sibling directory, `simple` branch).
- The `nix-secrets` flake input is configured for SSH auth with shallow clone.
- SOPS age keys are managed via `just` recipes: `sops-update-age-key`, `sops-update-user-age-key`, `sops-update-host-age-key`, `sops-add-creation-rules`.
- After a rebuild, `just check-sops` verifies sops-nix activated correctly.
- `just rekey` rekeys all sops files and pushes to the secrets repo.

## Pre-commit Hooks

`.pre-commit-config.yaml` is **auto-generated by git-hooks.nix** — do not edit it directly. Configure hooks in `checks.nix`. Active hooks: nixfmt-rfc-style, deadnix (with `--no-lambda-arg`), shellcheck, shfmt, check-added-large-files, and others.

## Adding a New Feature

Features are self-contained modules under `modules/features/`. Each feature configures both NixOS system settings and Home Manager user settings.

### Step 1: Create the feature directory

```bash
mkdir -p modules/features/<feature-name>/
```

### Step 2: Create `default.nix` (NixOS-level)

This file handles system-level config and wires the HM config:

```nix
# modules/features/<feature-name>/default.nix
{ config, ... }:
let
  username = config.hostSpec.username;
in
{
  # === NixOS system config ===
  # e.g., programs.foo.enable = true;
  # e.g., services.bar.enable = true;

  # === Wire Home Manager config ===
  home-manager.users.${username}.imports = [ ./home.nix ];
}
```

If the feature has **no NixOS-level config** (only HM), the `default.nix` can be minimal:

```nix
# modules/features/<feature-name>/default.nix
{ config, ... }:
let
  username = config.hostSpec.username;
in
{
  home-manager.users.${username}.imports = [ ./home.nix ];
}
```

### Step 3: Create `home.nix` (HM-level)

```nix
# modules/features/<feature-name>/home.nix
{ config, lib, pkgs, osConfig, ... }:
let
  hostSpec = osConfig.hostSpec;
in
{
  # === Packages ===
  home.packages = with pkgs; [ ... ];

  # === Program config ===
  programs.foo = {
    enable = true;
    # ... settings ...
  };
}
```

**Note:** Use `osConfig.hostSpec` to access host metadata from within HM modules.

### Step 4: Add the feature to host(s)

Edit `modules/hosts/<hostname>.nix` and add the feature to the `imports` list:

```nix
# modules/hosts/fw-16.nix
{ ... }:
{
  imports = [
    # ... existing imports ...
    ../features/<feature-name>
  ];
}
```

### Step 5: Verify

```bash
nix fmt
just check
```

### Feature with Sub-Modules

If a feature has multiple sub-components (e.g., `desktop` has `mango.nix`, `dms.nix`, `gtk.nix`), each sub-module is a separate file imported by the host:

```nix
# modules/hosts/fw-16.nix
imports = [
  ../features/desktop           # base desktop config
  ../features/desktop/greeter.nix  # greeter sub-module
];
```

### Feature Variants (Stable vs Experimental)

When two hosts need the same feature but with different configs, use the variant pattern:

```
modules/features/<feature>/
├── common.nix              # Shared base config
├── stable/
│   └── default.nix         # Imports common.nix + stable overrides
└── experimental/
    └── default.nix         # Imports common.nix + experimental overrides
```

The host chooses which variant to import:

```nix
# modules/hosts/fw-16.nix (stable)
imports = [ ../features/<feature>/stable ];

# modules/hosts/experiment-laptop.nix (experimental)
imports = [ ../features/<feature>/experimental ];
```

**When to use variants vs host-level overrides:**
- **Small tweak** (1-2 settings) → override directly in the host file
- **Significant divergence** (different packages, experimental features) → create a variant
- **3+ hosts share the same variant** → create a variant (reusable "profile")
- **Temporary experiment** (< 1 week) → host-level override

## Adding a New Host

### Step 1: Create hardware config

```bash
mkdir -p hosts/nixos/<hostname>/
# Copy hardware-configuration.nix from the machine
```

```nix
# hosts/nixos/<hostname>/default.nix
{ inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    # ... hardware-specific modules ...
  ];

  system.stateVersion = "24.11";
}
```

### Step 2: Create host declaration with feature list

```nix
# modules/hosts/<hostname>.nix
{ ... }:
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
    ../features/bat
    ../features/ssh
    ../features/sops

    # === Add host-specific features here ===

    # === Hardware + host-specific config ===
    ../../hosts/nixos/<hostname>
  ];

  hostSpec = {
    hostName = "<hostname>";
    # Optional: nixConfigPath = "/home/tryy3/nix-config";
  };
}
```

### Step 3: Register in flake.nix

Add the hostname to the `nixosHosts` array in `flake.nix`:

```nix
nixosHosts = [
  "fw-16"
  "nexer-wsl"
  "<hostname>"
];
```

### Step 4: Create HM override file (optional)

```nix
# home/tryy3/<hostname>.nix
{ ... }:
{
  # Host-specific HM overrides that don't belong in any feature module.
  # Usually empty — most config should live in feature modules.
}
```

### Step 5: Verify

```bash
nix fmt
just check
```

## Adding a New Package

1. **Existing nixpkgs package:** Add to the appropriate feature module's `home.packages` in its `home.nix`, or to `modules/base/home.nix` if it's a core package needed on all hosts.
2. **Custom package:** Add a directory under `pkgs/common/` with a `default.nix` — it's auto-discovered and available via the overlay.

## Host-Specific Overrides

When a feature needs different behavior per host, there are three approaches:

### 1. Conditional in the Feature Module

```nix
# modules/features/shell/aliases.nix
{ osConfig, lib, ... }:
let
  hostName = osConfig.hostSpec.hostName;
in
{
  ls = "eza";
  wsl-open = lib.mkIf (hostName == "nexer-wsl") "explorer.exe .";
}
```

### 2. Host-Level Override

```nix
# modules/hosts/nexer-wsl.nix
{ lib, ... }:
{
  imports = [ ../base ../features/shell /* ... */ ];

  hostSpec = { hostName = "nexer-wsl"; };

  # Override shell aliases just for this host
  home-manager.users.tryy3.programs.zsh.shellAliases = {
    wsl-open = "explorer.exe .";
  };
}
```

### 3. Using `hostSpec` Flags

Define flags in `hostSpec` and use them in feature modules:

```nix
# modules/hosts/nexer-wsl.nix
hostSpec = {
  hostName = "nexer-wsl";
  isWsl = true;
};

# modules/features/shell/default.nix
{ config, lib, ... }:
let
  hostSpec = config.hostSpec;
in
{
  home-manager.users.${hostSpec.username}.programs.zsh.plugins =
    lib.optionals (!hostSpec.isWsl) [
      { name = "zsh-term-title"; src = "..."; }
    ];
}
```

## Gotchas

- **`direnv allow`** must be run after cloning. The `.envrc` uses `use flake`.
- **`nix-secrets` must be a sibling directory** at `../nix-secrets`.
- **`--impure` is required** for `nixos-rebuild` and `nix flake check` because the config references `REPO_PATH` and `hostname` at build time.
- **Git submodules are forbidden** by pre-commit hooks (except `.agents/skills/nixos`).
- **`.pre-commit-config.yaml` is generated** — edit `checks.nix` instead.
- **`result` and `latest.iso` are gitignored** — build outputs won't pollute the repo.
- **`home/tryy3/<hostname>.nix` is for overrides only** — most HM config should live in feature modules, not in these files.
- **`scanPaths` is deprecated for module discovery** — use explicit imports in host declarations instead.
