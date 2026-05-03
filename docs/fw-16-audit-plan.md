# fw-16 Audit Remediation Plan

> Derived from: `docs/fw-16-audit-recommendations.md`
> Sorted: simple → advanced so we can tick off quick wins first.

## Skipped (per user decision)

| # | Item | Reason |
|---|------|--------|
| 4 | GPU bus IDs fragile with kernel updates | Current setup is acceptable; revisit if it breaks |
| 11 | `nixpkgs-darwin` input with no darwin hosts | Keep for now; will be part of a broader cleanup |
| 12 | Clean up starter template FIXMEs | Keep for now; will be part of a broader cleanup |
| 18 | Hardcoded git user info | Deferred — other git changes planned first |
| 20 | Empty optional modules still imported | Keep for now; will be part of the broader cleanup (11-12) |

---

## Tier 1 — Trivial fixes (typos, dead config, duplicates)

### Task 1 — Fix spelling errors (audit #13)

**Files:**
- `hosts/common/core/nixos.nix:22` — "garbace" → "garbage"
- `home/tryy3-fw/common/core/zsh/default.nix:21` — "replacce" → "replace"
- `home/tryy3-fw/common/core/zsh/default.nix:27` — "hiden" → "hidden"
- `home/tryy3-fw/common/core/zsh/default.nix:79` — "preffixed" → "prefixed"
- `home/tryy3-fw/common/core/zsh/default.nix:92` — "oxConfig" → "osConfig"

**Action:** Straightforward find-and-replace in comments.

---

### Task 2 — Fix "oxConfig" → "osConfig" in zsh aliases import (audit #17)

**File:** `home/tryy3-fw/common/core/zsh/default.nix:92`

```nix
shellAliases = import ./aliases.nix { inherit osConfig; };
# TODO: look at oxConfig from nix-config
```

The comment says `oxConfig` but should say `osConfig`. The `osConfig` parameter itself is already correctly passed — this is just a comment typo.

**Action:** Fix the comment. Also verify that `osConfig` is actually used in `aliases.nix` (currently it's passed but the file uses `{ ... }:` which discards it).

---

### Task 3 — Remove dead `services.xserver.xkb.layout` on Wayland (audit #16)

**File:** `hosts/nixos/fw-16/default.nix:137`

```nix
services.xserver.xkb.layout = "se";
```

This sets the X11 keyboard layout, but fw-16 runs Wayland (MangoWC). The keyboard is already configured via `console.keyMap = "sv-latin1"` (TTY) and `xkb_rules_layout = "se"` (MangoWC).

**Action:** Remove the `services.xserver.xkb.layout = "se"` line.

---

### Task 4 — Remove duplicate `ssh-agent` from HM nixos.nix (audit #7)

**Files:**
- `home/tryy3-fw/common/core/default.nix:39` — `services.ssh-agent.enable = true;` (cross-platform)
- `home/tryy3-fw/common/core/nixos.nix:14` — `services.ssh-agent.enable = true;` (Linux-only, redundant)

**Action:** Remove `services.ssh-agent.enable = true;` from `nixos.nix` since it's already set in the cross-platform `default.nix`.

---

## Tier 2 — Small structural changes

### Task 5 — Remove `lib.flatten` from import lists (audit #14)

**Files:**
- `hosts/nixos/fw-16/default.nix:18`
- `hosts/common/core/default.nix:19`
- `home/tryy3-fw/common/core/default.nix:13`

`lib.flatten` wrapping the entire import list can silently deduplicate when you'd want to know about duplicate entries.

**Action:** Replace `lib.flatten [ ... ]` with just `[ ... ]` in all three files. Verify with `just check` that no duplicates exist.

---

### Task 6 — Use variables instead of hardcoded paths in mango.nix (audit #9)

**File:** `home/tryy3-fw/common/optional/mango.nix`

Two hardcoded paths:
- Line 418: `"SUPER+SHIFT,F1,spawn,/home/tryy3-fw/.config/mango/scripts/restore-nix-dev.sh"`
- Line 70: `output-filename = "/home/tryy3-fw/Pictures/Screenshots/satty-..."`

**Action:** Use `${config.home.homeDirectory}` (or `${config.hostSpec.home}`) for both paths. The mango HM module has access to `config` from home-manager.

---

### Task 7 — Disable system-wide zsh, keep only HM-level (audit #8) — REVERTED

**Files:**
- `hosts/common/users/primary/default.nix:40` — `programs.zsh.enable = true;` (system-level)
- `home/tryy3-fw/common/core/zsh/default.nix:50` — `programs.zsh.enable = true;` (HM-level)

**Action:** Initially removed `programs.zsh.enable = true` from `hosts/common/users/primary/default.nix`, but NixOS has an assertion that requires it when zsh is set as a login shell. **Reverted** — `programs.zsh.enable = true` stays at the system level with a clarifying comment that HM handles configuration.

---

### Task 8 — Enable IPv6 (audit #6)

**File:** `hosts/nixos/fw-16/default.nix:95`

```nix
enableIPv6 = false;
```

IPv6 is broadly recommended for modern networking. Tailscale, Podman, and many services expect it.

**Action:** Remove `enableIPv6 = false;` (or set `enableIPv6 = true;` explicitly if preferred). The default in NixOS is already `true`, so simply removing the line is sufficient.

---

### Task 9 — Try disabling `allow-import-from-derivation` (audit #2)

**File:** `hosts/common/core/default.nix:101`

```nix
allow-import-from-derivation = true;
```

IFD can run arbitrary code at evaluation time. Unless something specifically requires it, this should be `false`.

**Action:** Change to `allow-import-from-derivation = false;` and run `just check` to see if anything breaks. If the build fails, revert and document why IFD is needed.

---

### Task 10 — Make wifi PSK sops secrets more explicit (audit #3)

**File:** `hosts/nixos/fw-16/default.nix:87-91`

```nix
sops.secrets."wifi/home-psk" = { };
```

Currently uses empty sops secrets declaration with default mode/owner. Should be more explicit about permissions.

**Action:** Add explicit `mode`, `owner`, and `group` to the sops secret declaration for better security posture:

```nix
sops.secrets."wifi/home-psk" = {
  mode = "0400";
  owner = config.users.users.${config.hostSpec.username}.name;
  group = config.users.users.${config.hostSpec.username}.group;
};
```

---

## Tier 3 — Advanced changes (require more care/testing)

### Task 11 — Evaluate GPU PCI ID: dynamic lookup or keep hardcoded (audit #15)

**File:** `home/tryy3-fw/common/optional/dank-material-shell.nix:112`

```nix
gpuPciId = "10de:2d58";
```

**Action:** Investigate whether Quickshell/DMS supports a dynamic GPU lookup. If not, keep hardcoded with a comment noting the dependency. This is a minor change — if it breaks, easy to revert.

---

### Task 12 — Remove `nix-ld` from FW host (audit #19)

**File:** `hosts/common/core/nixos.nix:39`

```nix
programs.nix-ld.enable = true;
```

This is in the shared core, so removing it affects all hosts. The user's WSL machine may still need it.

**Action:** Move `programs.nix-ld.enable = true;` out of the shared core and into individual host configs that need it (e.g., WSL). For the FW host, don't enable it. If this requires too many changes across hosts, keep it in core.

---

### Task 13 — Add `hostSpec.nixConfigPath` for per-host flake path (audit #1)

**Files:**
- `modules/common/host-spec.nix` — add new option
- `hosts/common/core/nixos.nix:31` — use new option instead of hardcoded path
- `home/tryy3-fw/common/core/default.nix:49` — use new option for FLAKE variable

Currently:
- `nixos.nix`: `flake = "${config.hostSpec.home}/nix-config";` (wrong path)
- `home/default.nix`: `FLAKE = "$HOME/src/nix/nix-config";` (correct path)

The user has two machines with different nix-config paths:
- FW: `~/src/nix/nix-config`
- WSL: `~/nix-config`

**Action:**
1. Add a `nixConfigPath` option to `hostSpec` in `modules/common/host-spec.nix` with a sensible default (e.g., `"${hostSpec.home}/src/nix/nix-config"`).
2. Override per-host where needed (e.g., WSL would set `nixConfigPath = "${hostSpec.home}/nix-config"`).
3. Use `config.hostSpec.nixConfigPath` in both `nixos.nix` (nh flake path) and `home/default.nix` (FLAKE session variable).

---

### Task 14 — Switch `linuxPackages_latest` → `linuxPackages_7_0` (audit #5)

**File:** `hosts/nixos/fw-16/default.nix:134`

```nix
boot.kernelPackages = pkgs.linuxPackages_latest;
```

Linux 7.0 has been released. Using `linuxPackages_latest` on a hybrid GPU laptop with NVIDIA PRIME is fragile.

**Action:** Change to `pkgs.linuxPackages_7_0` for a stable, known-good kernel. Verify that `linuxPackages_7_0` exists in the current nixpkgs. After the change, verify GPU bus IDs still match (audit #4 concern).

---

### Task 15 — Add explicit host whitelist for nixosConfigurations (audit #10)

**File:** `flake.nix:39-50`

Currently auto-discovers all directories under `hosts/nixos/`, which includes template hosts (`hostname1`) and the ISO builder (`iso`).

**Action:** Replace the auto-discovery with an explicit whitelist:

```nix
nixosConfigurations = builtins.listToAttrs (
  map (host: {
    name = host;
    value = nixpkgs.lib.nixosSystem { ... };
  }) [ "fw-16" ]  # explicit list of real hosts
);
```

Keep `hostname1` and `iso` directories in `hosts/nixos/` for future use, but don't auto-register them as `nixosConfigurations`.
