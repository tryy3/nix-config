# AGENTS.md

## ⛔ CRITICAL: NEVER AUTO-BUILD ⛔

**NEVER run `just rebuild`, `just rebuild-trace`, `just rebuild-full`, `just rebuild-update`, `nixos-rebuild`, `nh os switch`, or any other command that builds and/or switches the system configuration.**

This is critical for two reasons:
1. **Security** — a build/switch applies changes to a running system. An incorrect config can lock you out, expose secrets, or break networking.
2. **Privilege** — these commands occasionally require `sudo`, which will hang or fail in an agent context.

If you determine that a build or switch is needed, **stop and ask the user to run the command themselves.** You may prepare the changes, verify them with `just check` or `nix fmt`, but the final build/switch step must always be user-initiated.

## What This Repo Is

A flake-based NixOS configuration (with nix-darwin support commented out). Manages multiple hosts with shared modules, home-manager, sops-nix secrets, and custom overlays.

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

### Directory Layout

- **`hosts/nixos/<hostname>/default.nix`** — NixOS host definitions. Auto-discovered by `builtins.readDir ./hosts/nixos`, so adding a directory here automatically registers a new `nixosConfigurations` entry.
- **`home/<username>/<hostname>.nix`** — Per-user, per-host home-manager config. Wired in from `hosts/common/users/primary/default.nix` via `hostSpec.username` and `hostSpec.hostName`.
- **`home/<username>/common/`** — Shared home-manager config for that user (core + optional).
- **`modules/common/`** — Reusable NixOS modules shared across platforms. Auto-imported via `lib.custom.scanPaths`.
- **`modules/hosts/common/`** — Host-level modules shared across NixOS and Darwin. Auto-imported.
- **`modules/hosts/nixos/`** — NixOS-specific host modules. Auto-imported.
- **`modules/home/`** — Home-manager modules. Auto-imported.
- **`pkgs/common/`** — Custom packages. Auto-discovered via `packagesFromDirectoryRecursive`.
- **`overlays/default.nix`** — Overlays: adds custom packages, `pkgs.stable.*`, `pkgs.unstable.*`.
- **`lib/default.nix`** — Custom lib functions: `relativeToRoot`, `scanPaths`, `scanPathsFilterPlatform`.
- **`nixos-installer/`** — Separate flake for remote NixOS installation.

### Conventions

- **`lib.custom.relativeToRoot`** — Used everywhere to reference files from repo root (e.g., `"hosts/common/core"`). Equivalent to `lib.path.append ../.` applied to the string.
- **`lib.custom.scanPaths`** — Auto-imports all `.nix` files and directories (excluding `default.nix`) from a given path. Used in module `default.nix` files.
- **`lib.custom.scanPathsFilterPlatform`** — Like `scanPaths` but excludes `darwin.nix`/`nixos.nix` files that don't match the current platform.
- **`hostSpec`** — Custom option module (`modules/common/host-spec.nix`) that declares host metadata (username, hostname, email, isMinimal, isWork, etc.). Set per-host, consumed everywhere.
- **Platform-specific files** — Use `nixos.nix` or `darwin.nix` suffixes. `scanPathsFilterPlatform` filters them automatically.
- **`#FIXME(starter)`** — Comments throughout the repo mark places that need customization for your setup.

### How Hosts Are Wired

1. `flake.nix` auto-discovers hosts from `hosts/nixos/` directories.
2. Each host's `default.nix` imports `hosts/common/core`, which imports `modules/common`, `modules/hosts/common`, `modules/hosts/nixos`, and `hosts/common/users/primary`.
3. `hosts/common/users/primary/default.nix` sets up the user and imports `home/<username>/<hostname>.nix` for home-manager.
4. Home-manager configs import `modules/home` and use `scanPathsFilterPlatform` for platform filtering.

## Secrets (sops-nix)

- Secrets live in a **separate repo** at `../nix-secrets` (sibling directory, `simple` branch).
- The `nix-secrets` flake input is configured for SSH auth with shallow clone.
- SOPS age keys are managed via `just` recipes: `sops-update-age-key`, `sops-update-user-age-key`, `sops-update-host-age-key`, `sops-add-creation-rules`.
- After a rebuild, `just check-sops` verifies sops-nix activated correctly.
- `just rekey` rekeys all sops files and pushes to the secrets repo.

## Pre-commit Hooks

`.pre-commit-config.yaml` is **auto-generated by git-hooks.nix** — do not edit it directly. Configure hooks in `checks.nix`. Active hooks: nixfmt-rfc-style, deadnix (with `--no-lambda-arg`), shellcheck, shfmt, check-added-large-files, and others.

## Overlays

`pkgs.stable` and `pkgs.unstable` are available in all NixOS/home-manager configs via overlays in `overlays/default.nix`. Use `pkgs.stable.<pkg>` or `pkgs.unstable.<pkg>` to pin specific packages.

## Adding a New Package

1. Add to `home/<username>/common/core/default.nix` under `home.packages` using `builtins.attrValues { inherit (pkgs) ...; }`.
2. For a custom package, add a directory under `pkgs/common/` with a `default.nix` — it's auto-discovered.

## Adding a New Host

1. Create `hosts/nixos/<hostname>/default.nix` (copy from `host.nix` or an existing host).
2. Create `home/<username>/<hostname>.nix` (copy from an existing one).
3. The host is auto-discovered by the flake — no need to edit `flake.nix`.

## Gotchas

- **`direnv allow`** must be run after cloning. The `.envrc` uses `use flake`.
- **`nix-secrets` must be a sibling directory** at `../nix-secrets`.
- **`--impure` is required** for `nixos-rebuild` and `nix flake check` because the config references `REPO_PATH` and `hostname` at build time.
- **Git submodules are forbidden** by pre-commit hooks (except `.agents/skills/nixos`).
- **`.pre-commit-config.yaml` is generated** — edit `checks.nix` instead.
- **`result` and `latest.iso` are gitignored** — build outputs won't pollute the repo.
