#NOTE(starter): custom functions added here are available via `lib.custom.foo` by passing `lib` into
# the expression parameters. The two functions below are used by `nix-config` and should not be modified.
{ lib, ... }:
{
  # use path relative to the root of the project
  relativeToRoot = lib.path.append ../.;
  scanPaths =
    path:
    builtins.map (f: (path + "/${f}")) (
      builtins.attrNames (
        lib.attrsets.filterAttrs (
          path: _type:
          (_type == "directory") # include directories
          || (
            (path != "default.nix") # ignore default.nix
            && (lib.strings.hasSuffix ".nix" path) # include .nix files
          )
        ) (builtins.readDir path)
      )
    );
  # Like scanPaths but filters out platform-specific files (darwin.nix / nixos.nix)
  # that don't match the current platform
  scanPathsFilterPlatform =
    path:
    builtins.map (f: (path + "/${f}")) (
      builtins.attrNames (
        lib.attrsets.filterAttrs (
          name: _type:
          (_type == "directory") # include directories
          || (
            (name != "default.nix") # ignore default.nix
            && (name != "darwin.nix") # exclude darwin.nix (imported conditionally)
            && (name != "nixos.nix") # exclude nixos.nix (imported conditionally)
            && (lib.strings.hasSuffix ".nix" name) # include .nix files
          )
        ) (builtins.readDir path)
      )
    );
}
