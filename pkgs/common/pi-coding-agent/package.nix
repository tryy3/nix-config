{
  lib,
  buildNpmPackage,
  fetchurl,
  makeWrapper,
  nodejs,
}:
# Strategy: Pi is published as a pre-built npm package with compiled dist/.
# We avoid building from the monorepo source (workspace resolution, tsgo
# compilation chain) by fetching the npm registry tarball instead.
#
# The npm tarball doesn't include a package-lock.json, so we commit a
# standalone one (generated with `npm install --package-lock-only`) next
# to this file.  Update it on version bumps by running:
#
#   cd /tmp && mkdir pi-lockgen && cd pi-lockgen
#   cat > package.json << 'EOF'
#   { "name": "gen", "version": "0.0.0", "private": true,
#     "dependencies": { "@earendil-works/pi-coding-agent": "X.Y.Z" } }
#   EOF
#   nix-shell -p nodejs --run "npm install --package-lock-only --legacy-peer-deps"
#   cp package-lock.json /path/to/pkgs/common/pi-coding-agent/
let
  version = "0.74.0";
in
  buildNpmPackage rec {
    pname = "pi-coding-agent";
    inherit version;

    nativeBuildInputs = [
      makeWrapper
      nodejs
    ];

    # Pre-built npm package — contains dist/, package.json, docs, examples.
    # No TypeScript compilation needed.
    src = fetchurl {
      url = "https://registry.npmjs.org/@earendil-works/pi-coding-agent/-/pi-coding-agent-${version}.tgz";
      hash = "sha256-l0pzuWGVvX1jDhFYaey14N16XDo47kkm3JlEhmPUo0Q=";
    };

    npmDepsHash = "sha256-QMlpN0SUd2tHleHQXVOXmaACX7QiBn79MzG1Ir7Y2yU=";

    # npm tarball extracts into "package/".
    sourceRoot = "package";

    # The npm registry tarball doesn't include package-lock.json.
    # Copy in the standalone lockfile we committed alongside this file.
    # Also strip devDependencies — the npm package is pre-built and doesn't
    # need them at runtime.  Without this, npm install tries to resolve dev
    # deps from the lockfile even with --omit=dev, causing ENOTCACHED errors
    # because the prefetched cache only contains production deps.
    postPatch = ''
      cp ${./package-lock.json} package-lock.json
      chmod +w package-lock.json
      ${lib.getExe nodejs} -e "
        const fs = require('fs');
        const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
        delete pkg.devDependencies;
        fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
      "
    '';

    # The npm package is pre-built — dist/ already exists.  Skip the default
    # "npm run build" which would fail (no TypeScript source in the tarball).
    dontBuild = true;

    # Only install production dependencies — Pi is pre-built and doesn't
    # need devDependencies (TypeScript, vitest, etc.) at runtime.
    npmFlags = ["--omit=dev"];

    # Wrap the CLI with node so it works without node on the user's PATH.
    postInstall = ''
      rm $out/bin/pi
      makeWrapper ${lib.getExe nodejs} $out/bin/pi \
        --add-flags "$out/lib/node_modules/@earendil-works/pi-coding-agent/dist/cli.js"
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
