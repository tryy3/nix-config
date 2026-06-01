#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/update-pi.sh <version>
#
# Streamlines updating the pi-coding-agent package with yarn-berry v4:
#   1. Generates yarn.lock for the new version
#   2. Generates missing-hashes.json (for optional/platform-specific deps)
#   3. Updates the version string in package.nix
#   4. Pre-computes the offlineCache hash via yarn-berry-fetcher prefetch
#
# After running, you still need to update src.hash — the next build will
# print the expected value.  Then run alejandra . && just check.

VERSION="${1:?Usage: $0 <version>}"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PKG_DIR="$REPO_ROOT/pkgs/common/pi-coding-agent"
PACKAGE_NIX="$PKG_DIR/package.nix"
YARN_LOCK="$PKG_DIR/yarn.lock"
MISSING_HASHES="$PKG_DIR/missing-hashes.json"

# --- helpers ---
function red() {
	echo -e "\x1B[31m[!] $1 \x1B[0m"
}
function green() {
	echo -e "\x1B[32m[+] $1 \x1B[0m"
}
function yellow() {
	echo -e "\x1B[33m[*] $1 \x1B[0m"
}

# --- validate ---
if [ ! -f "$PACKAGE_NIX" ]; then
	red "package.nix not found at $PACKAGE_NIX"
	exit 1
fi

# --- 1. Generate yarn.lock ---
green "Generating yarn.lock for pi-coding-agent $VERSION ..."

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cd "$TMP"
cat >package.json <<EOF
{
  "name": "pi-lockfile-generator",
  "private": true,
  "dependencies": {
    "@earendil-works/pi-coding-agent": "$VERSION"
  }
}
EOF

# Resolve the flake's pinned nixpkgs (NOT system channel) so the yarn.lock
# format matches the yarn-berry version used at build time.
NIXPKGS="$(nix eval --impure --expr 'let f = builtins.getFlake (toString ./..); in f.inputs.nixpkgs.outPath' --raw)"

# Use yarn-berry from the flake's nixpkgs (yarn 4.x) to generate a v4 yarn.lock.
# --mode=update-lockfile skips linking node_modules, producing only the lockfile.
nix shell "$NIXPKGS#nodejs" "$NIXPKGS#yarn-berry_4" -c \
	yarn install --mode=update-lockfile

cp yarn.lock "$YARN_LOCK"
green "yarn.lock written to $YARN_LOCK"

# --- 2. Generate missing-hashes.json ---
# Yarn v4 doesn't write integrity hashes for optional/platform-specific
# dependencies (by design).  pi has @mariozechner/clipboard with per-platform
# optional deps that need this.  The yarn-berry-fetcher queries the registry
# for the missing hashes.
green "Generating missing-hashes.json ..."
nix run "$NIXPKGS#yarn-berry_4.yarn-berry-fetcher" -- \
	missing-hashes "$YARN_LOCK" >"$MISSING_HASHES"
green "missing-hashes.json written to $MISSING_HASHES"

# --- 3. Pre-compute offlineCache hash ---
green "Computing offlineCache hash with yarn-berry-fetcher prefetch ..."
HASH=$(nix run "$NIXPKGS#yarn-berry_4.yarn-berry-fetcher" -- \
	prefetch "$YARN_LOCK" "$MISSING_HASHES" 2>/dev/null || true)
if [ -n "$HASH" ]; then
	sed -i "s|hash = \"sha256-[^\"]*\"; # yarn-berry-offlineCache|hash = \"$HASH\"; # yarn-berry-offlineCache|" "$PACKAGE_NIX"
	green "offlineCache hash updated: $HASH"
else
	yellow "prefetch failed — set offlineCache hash manually with lib.fakeHash"
fi

# --- 4. Update version in package.nix ---
green "Updating version in package.nix ..."
sed -i "s/version = \".*\";/version = \"$VERSION\";/" "$PACKAGE_NIX"

# --- Stage new files for git (Nix flakes read from git index) ---
if git -C "$REPO_ROOT" rev-parse --git-dir &>/dev/null 2>&1; then
	git -C "$REPO_ROOT" add "$YARN_LOCK" "$MISSING_HASHES" "$PACKAGE_NIX"
	green "Staged yarn.lock, missing-hashes.json, and package.nix for git"
fi

# --- summary ---
echo ""
green "Done! $PACKAGE_NIX updated."
yellow "Next steps:"
echo "  1. Update src.hash in $PACKAGE_NIX"
echo "     (set hash = lib.fakeHash; rebuild; copy the expected hash)"
echo "  2. Run: alejandra . && just check"
