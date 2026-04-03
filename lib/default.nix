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
  leaf = str: lib.last (lib.splitString "/" str);
  scanPathsFilterPlatform =
    path:
    lib.filter (
      path: lib.match "nixos.nix|darwin.nix|nixos|darwin" (leaf (builtins.toString path)) == null
    ) (scanPaths path);
}
