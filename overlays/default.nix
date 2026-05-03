#
# This file defines overlays/custom modifications to upstream packages
#

{ inputs, ... }:

let
  # Add in custom packages from this config
  additions =
    final: prev:
    (prev.lib.packagesFromDirectoryRecursive {
      callPackage = prev.lib.callPackageWith final;
      directory = ../pkgs/common;
    });

  linuxModifications = final: prev: prev.lib.mkIf final.stdenv.isLinux { };

  modifications = final: prev: {
    # example = prev.example.overrideAttrs (oldAttrs: let ... in {
    # ...
    # });

    # Bump omnictl to match Omni backend (nixpkgs is currently on 1.3.4).
    # 1.6.1 requires Go 1.26+, so we also override the Go toolchain used.
    omnictl =
      (prev.omnictl.override { buildGoModule = prev.buildGo126Module; }).overrideAttrs
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

in
{
  default =
    final: prev:

    (additions final prev)
    // (modifications final prev)
    // (linuxModifications final prev)
    // (stable-packages final prev)
    // (unstable-packages final prev);
}
