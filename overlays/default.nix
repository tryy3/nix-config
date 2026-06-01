#
# This file defines overlays/custom modifications to upstream packages
#
{inputs, ...}: let
  # Add in custom packages from this config
  additions = final: prev: (prev.lib.packagesFromDirectoryRecursive {
    callPackage = prev.lib.callPackageWith final;
    directory = ../pkgs/common;
  });

  linuxModifications = final: prev: prev.lib.mkIf final.stdenv.isLinux {};

  modifications = final: prev: {
    # example = prev.example.overrideAttrs (oldAttrs: let ... in {
    # ...
    # });

    # Fix the nixpkgs offline patch for yarn-berry 4.14.1.
    # --
    # 4.14.1 added LOCKFILE_MIGRATION_RULES with v < 9 selectors (for new
    # config defaults approvedGitRepositories + enableScripts).  These
    # match lockfile format 8, and the existing nixpkgs offline patch
    # unconditionally throws when ANY migration rule matches, producing:
    #   "expects lockfile version 8, but found lockfile version 8"
    # --
    # The fix: make the throw conditional — only fire it when the lockfile
    # version is NOT 8 (i.e., a genuine format mismatch).  Safe config
    # migrations for version 8 are allowed through.
    # --
    # This postPatch runs after the offline patch is applied (in
    # yarn-berry-offline), fixing the throw condition without modifying
    # the upstream patch file itself.
    # Remove this override once nixpkgs updates the offline patch.
    yarn-berry_4 = prev.yarn-berry_4.overrideAttrs (old: {
      postPatch =
        (old.postPatch or "")
        + ''
          # Fix the offline patch's false-positive throw for v < 9 migration rules.
          # Original: throw unconditionally when any migration rule matches.
          # Fixed:    only throw when lockfile version != 8 (genuine mismatch).
          # Safe config defaults (approvedGitRepositories, enableScripts) for
          # format 8 are allowed through.
          echo "Applying yarn-berry_4 postPatch fix for v < 9 migration rules"
          target=packages/plugin-essentials/sources/commands/install.ts
          if grep -q 'Tried to use yarn-berry_4.yarnConfigHook' "$target" 2>/dev/null; then
            sed -i '/Tried to use yarn-berry_4.yarnConfigHook/ {
              s/throw new Error(`Tried to use yarn-berry_4.yarnConfigHook/if (lockfileLastVersion != 8) { &/
              s/`);$/`); }/
            }' "$target"
            echo "  -> fixed"
          else
            echo "  -> skipped (offline patch not applied to this derivation)"
          fi
        '';
    });

    # Bump omnictl to match Omni backend (nixpkgs is currently on 1.3.4).
    # 1.6.1 requires Go 1.26+, so we also override the Go toolchain used.
    omnictl =
      (prev.omnictl.override {buildGoModule = prev.buildGo126Module;}).overrideAttrs
      (oldAttrs: rec {
        version = "1.6.1";
        src = prev.fetchFromGitHub {
          owner = "siderolabs";
          repo = "omni";
          rev = "v${version}";
          hash = "sha256-ncffAF1gEsCMeUszgqZExTSYRPkZ6em85S9thM1U3Sc=";
        };
        vendorHash = "sha256-snrOKwD4xbMTdjP13KLTVVB7ikXG+yHS8QT60/tHZ3I=";
      });
  };

  stable-packages = final: _prev: {
    stable = import inputs.nixpkgs-stable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
      #overlays = [
      #];
    };
  };

  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
      #overlays = [
      #];
    };
  };
in {
  default = final: prev:
    (additions final prev)
    // (modifications final prev)
    // (linuxModifications final prev)
    // (stable-packages final prev)
    // (unstable-packages final prev);
}
