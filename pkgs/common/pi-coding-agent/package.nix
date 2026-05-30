{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  nodejs,
  yarn-berry_4,
}:
# Strategy: Pi is published as a pre-built npm package with compiled dist/.
# We fetch the npm registry tarball (no build needed) and use yarn-berry v4
# to install its runtime dependencies.
#
# Yarn-berry avoids the npm 10.x integrity-hash bug that affected pi's
# monorepo sub-packages (pi-agent-core, pi-ai, pi-tui).  The yarn.lock
# file natively includes all integrity hashes.
#
# To update, run:
#
#   just update-pi <version>
let
  yarn-berry = yarn-berry_4;
  version = "0.78.0";
in
  stdenv.mkDerivation rec {
    pname = "pi-coding-agent";
    inherit version;

    nativeBuildInputs = [
      makeWrapper
      nodejs
      yarn-berry.yarnBerryConfigHook
    ];

    # Pre-built npm package — contains dist/, package.json, docs, examples.
    # No TypeScript compilation needed.
    src = fetchurl {
      url = "https://registry.npmjs.org/@earendil-works/pi-coding-agent/-/pi-coding-agent-${version}.tgz";
      hash = "sha256-oEfadYAdkTXjaKRxHQbQyktqtwiAGrgv0TZt3h7t0O4=";
    };

    # npm tarball extracts into "package/".
    sourceRoot = "package";

    # Yarn-berry fixed-output derivation — downloads all deps from yarn.lock
    # and validates their integrity hashes.  See yarn.lock + missing-hashes.json
    # alongside this file.
    missingHashes = ./missing-hashes.json;

    offlineCache = yarn-berry.fetchYarnBerryDeps {
      src = ./.;
      inherit missingHashes;
      hash = "sha256-tNbRI9o8FAwaM066jTM+VvKXybLvHYl7j3MNjxYN7WE="; # yarn-berry-offlineCache
    };

    # The npm registry tarball doesn't include yarn.lock — copy in the
    # standalone one committed alongside this file.  Also remove
    # npm-shrinkwrap.json (yarn ignores it, but keep the source clean).
    # Strip devDependencies — the package is pre-built and doesn't need
    # TypeScript, vitest, etc. at runtime.
    # Force node-modules linker — Yarn Berry defaults to PnP (.pnp.cjs)
    # but pi expects a traditional node_modules tree.
    postPatch = ''
      cp ${./yarn.lock} yarn.lock
      chmod +w yarn.lock
      rm -f npm-shrinkwrap.json

      # Force Yarn Berry to use the classic node_modules linker
      cat > .yarnrc.yml << 'YARNRC'
      nodeLinker: node-modules
      YARNRC

      ${lib.getExe nodejs} -e "
        const fs = require('fs');
        const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
        delete pkg.devDependencies;
        fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
      "
    '';

    # The npm package is pre-built — dist/ already exists.
    dontBuild = true;

    # Yarn-berry installs into node_modules in the build directory.
    # We need to copy the installed dependencies and pi's own files into $out,
    # then wrap the CLI executable.
    installPhase = ''
      runHook preInstall

      local dir="$out/lib/node_modules/@earendil-works/pi-coding-agent"
      mkdir -p "$dir" "$out/bin"

      # Copy pi's own files (matches the "files" list from package.json)
      cp -r dist docs examples CHANGELOG.md README.md package.json "$dir/"

      # Copy production dependencies installed by yarnBerryConfigHook
      cp -r node_modules "$dir/"

      # Wrap the CLI with node so it works without node on the user's PATH
      makeWrapper ${lib.getExe nodejs} $out/bin/pi \
        --add-flags "$dir/dist/cli.js"

      runHook postInstall
    '';

    meta = {
      description = "Minimal terminal coding agent harness — extensible, multi-provider, tree-structured sessions";
      homepage = "https://pi.dev";
      license = lib.licenses.mit;
      mainProgram = "pi";
      platforms = lib.platforms.linux ++ lib.platforms.darwin;
      maintainers = [lib.maintainers.tryy3];
    };
  }
