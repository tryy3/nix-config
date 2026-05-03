# fw-16 / tryy3-fw NixOS Configuration Audit

> Generated: 2026-05-02

## MUST Change (Critical)

### 1. NH flake path is wrong

**File:** `hosts/common/core/nixos.nix:31`

```nix
flake = "${config.hostSpec.home}/nix-config";
```

The actual config lives at `~/src/nix/nix-config`, not `~/nix-config`. This means `nh clean` and `nh os switch` won't find the flake. Compare with the HM `FLAKE` variable in `home/tryy3-fw/common/core/default.nix:49` which correctly uses `$HOME/src/nix/nix-config`.

### 2. `allow-import-from-derivation = true` enabled

**File:** `hosts/common/core/default.nix:101`

This is a reproducibility and security concern. IFD evaluation can run arbitrary network-accessing code at evaluation time. Unless something specifically requires it, this should be `false`.

### 3. Wifi PSK passed via environment variable

**File:** `hosts/nixos/fw-16/default.nix:89-91` and `:111`

The PSK ends up in `/run/secrets.d/...` as an env file with `HOME_PSK=<value>`. NetworkManager's `ensureProfiles.environmentFiles` is a relatively obscure mechanism. There's no explicit `sops.secrets` declaration with mode/owner restrictions — it's `{ }` which uses defaults.

---

## Good to Change (Recommended)

### 4. GPU bus IDs fragile with kernel updates

**File:** `hosts/nixos/fw-16/default.nix:143-151`

`amdgpuBusId = "PCI:194:0:0"` and `nvidiaBusId = "PCI:193:0:0"` come from `lspci` output — your own comment warns they must be verified after kernel updates. On a Framework 16 with `linuxPackages_latest`, this is a ticking time bomb. Consider:

- Using PCI stable names (`/dev/disk/by-path`-style)
- Adding a `lib.mkAssert` or boot-time check
- Pinning to a known-good kernel (`linuxPackages` instead of `linuxPackages_latest`)

### 5. `linuxPackages_latest` on hybrid GPU laptop

**File:** `hosts/nixos/fw-16/default.nix:134`

Latest kernel + bleeding-edge `nixos-hardware` module for Framework 16 AI 300 series + NVIDIA PRIME = fragile combination. A kernel update can break GPU selection, wifi, or suspend. Consider `linuxPackages` (the stable kernel for your nixpkgs release) unless you specifically need a newer kernel feature.

### 6. `networking.enableIPv6 = false`

**File:** `hosts/nixos/fw-16/default.nix:95`

Disabling IPv6 is broadly discouraged in modern networking. Tailscale, Podman, and many services expect or perform better with IPv6. Unless your ISP/router actually has IPv6 issues, keep it enabled.

### 7. `services.ssh-agent.enable = true` duplicated

**File:** `home/tryy3-fw/common/core/default.nix:39` and `home/tryy3-fw/common/core/nixos.nix:14`

The HM core `default.nix` already enables ssh-agent for all platforms. The `nixos.nix` file re-enables it for Linux, which is redundant.

### 8. `programs.zsh.enable = true` at two levels

**File:** `hosts/common/users/primary/default.nix:40` (system-level)
**File:** `home/tryy3-fw/common/core/zsh/default.nix:50` (HM-level)

Enabling ZSH at both the NixOS system level AND in home-manager is redundant. The HM module handles installation + configuration. The system-level enable is only needed if you want zsh as a login shell for root or non-HM users.

### 9. Hardcoded paths in mango.nix

**File:** `home/tryy3-fw/common/optional/mango.nix:418` and `:70`

```nix
"SUPER+SHIFT,F1,spawn,/home/tryy3-fw/.config/mango/scripts/restore-nix-dev.sh"
output-filename = "/home/tryy3-fw/Pictures/Screenshots/satty-..."
```

These should use `${config.home.homeDirectory}` or `${config.hostSpec.home}` to be portable.

### 10. Template hosts pollute `nixosConfigurations`

**File:** `flake.nix:39-50`

The auto-discovery via `builtins.readDir ./hosts/nixos` picks up `hostname1` (template) and `iso` (builder). While they won't be built unless requested, they appear in `nix flake show` and could confuse. Either:

- Move templates out of `hosts/nixos/`
- Add an explicit host whitelist/blacklist in the flake

### 11. `nixpkgs-darwin` input with no darwin hosts

**File:** `flake.nix:166`

No `darwinConfigurations` and no darwin hosts exist, but `nixpkgs-darwin` is fetched on every flake update. Adds evaluation overhead.

### 12. Clean up starter template FIXMEs

Many files contain `# FIXME(starter):` comments from the EmergentMind template (20+ across the codebase). These add noise and suggest unresolved configuration.

---

## Minor Tweaks (Quality of Life)

### 13. Spelling errors in comments

- `hosts/common/core/nixos.nix:22` — "garbace" -> "garbage"
- `home/tryy3-fw/common/core/zsh/default.nix:21` — "replacce" -> "replace"
- `home/tryy3-fw/common/core/zsh/default.nix:27` — "hiden" -> "hidden"
- `home/tryy3-fw/common/core/zsh/default.nix:79` — "preffixed" -> "prefixed"
- `home/tryy3-fw/common/core/zsh/default.nix:92` — "oxConfig" -> "osConfig"

### 14. `lib.flatten` on import lists can mask duplicates

**Files:** `hosts/nixos/fw-16/default.nix:18`, `hosts/common/core/default.nix:19`, `home/tryy3-fw/common/core/default.nix:13`

The `flatten` wrapping the whole import list is unnecessary and can silently deduplicate when you'd want to know about duplicates.

### 15. System monitor widget has hardcoded GPU PCI ID

**File:** `home/tryy3-fw/common/optional/dank-material-shell.nix:112`

`gpuPciId = "10de:2d58"` — if the GPU changes or this config is shared, this breaks silently.

### 16. `services.xserver.xkb.layout = "se"` unnecessary on Wayland

**File:** `hosts/nixos/fw-16/default.nix:137`

This configures X11 keyboard layout, but you're running Wayland (MangoWC). The keyboard is configured in `console.keyMap` for TTY and in mango's own settings (`xkb_rules_layout = "se"`). Not harmful, just dead config.

### 17. Dead ZSH plugin import without matching HM module

**File:** `home/tryy3-fw/common/core/zsh/default.nix:92`

```nix
shellAliases = import ./aliases.nix { inherit osConfig; };
```

The `osConfig` parameter is passed but the comment says `# TODO: look at oxConfig from nix-config`. Either the param is unused in `aliases.nix` or there's a pending feature.

### 18. Hardcoded git user info instead of using hostSpec/secrets

**File:** `home/tryy3-fw/common/core/git.nix:13-14`

```nix
user.name = "tryy3";
user.email = "github.com@compilethis.eu";
```

These should use `config.hostSpec.handle` and `config.hostSpec.email` (which come from your nix-secrets repo) for consistency.

### 19. `programs.nix-ld.enable = true` may not be needed

**File:** `hosts/common/core/nixos.nix:39`

This allows running pre-compiled non-Nix binaries. Useful for development, but on a desktop machine with full Nix packaging, you likely don't need it — and it adds a minor attack surface.

### 20. Empty optional modules still imported

**Files:** `home/tryy3-fw/common/optional/comms/default.nix`, `home/tryy3-fw/common/optional/media/default.nix`

These are imported (though commented out in `fw-16.nix`) but are empty skeleton files. Either delete them or populate them.
