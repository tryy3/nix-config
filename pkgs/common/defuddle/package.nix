{
  lib,
  buildNpmPackage,
  fetchurl,
  makeWrapper,
  nodejs,
}:

# Strategy: Defuddle is published as a pre-built npm package with compiled
# dist/ files.  We avoid building from the GitHub source (webpack + tsc toolchain)
# by fetching the npm registry tarball instead.
#
# The npm tarball doesn't include a package-lock.json, so we commit a
# standalone one (generated with `npm install --package-lock-only`) next
# to this file.  Update it on version bumps by running:
#
#   cd /tmp && mkdir defuddle-lockgen && cd defuddle-lockgen
#   cat > package.json << 'EOF'
#   { "name": "gen", "version": "0.0.0", "private": true,
#     "dependencies": { "defuddle": "X.Y.Z" } }
#   EOF
#   nix-shell -p nodejs --run "npm install --package-lock-only --legacy-peer-deps"
#   cp package-lock.json /path/to/pkgs/common/defuddle/
let
  version = "0.18.1";
in
buildNpmPackage rec {
  pname = "defuddle";
  inherit version;

  nativeBuildInputs = [
    makeWrapper
    nodejs
  ];

  # Pre-built npm package — contains dist/, package.json, README, LICENSE.
  # No TypeScript/webpack compilation needed.
  src = fetchurl {
    url = "https://registry.npmjs.org/defuddle/-/defuddle-${version}.tgz";
    hash = "sha256-KdY0s+Yz58oL1W/LYpZhGx+F4YI82bwf4yIPERIUmuw=";
  };

  npmDepsHash = "sha256-Un+ek2V8AwZfie8ZZDHDtUBnMWaC4/605hFpmtzO8UQ=";

  # npm tarball extracts into "package/".
  sourceRoot = "package";

  # The npm registry tarball doesn't include package-lock.json.
  # Copy in the standalone lockfile we committed alongside this file.
  # Also strip devDependencies — the npm package is pre-built and doesn't
  # need them at runtime.
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
  # "npm run build" which would fail (no TypeScript/webpack source in the
  # tarball).
  dontBuild = true;

  # Only install production dependencies — Defuddle is pre-built and doesn't
  # need devDependencies at runtime.
  npmFlags = [ "--omit=dev" ];

  # Wrap the CLI so it works without node on the user's PATH.
  postInstall = ''
    makeWrapper ${lib.getExe nodejs} $out/bin/defuddle \
      --add-flags "$out/lib/node_modules/defuddle/dist/cli.js"
  '';

  meta = {
    description = "Extract article content and metadata from web pages";
    homepage = "https://github.com/kepano/defuddle";
    license = lib.licenses.mit;
    mainProgram = "defuddle";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    maintainers = [ lib.maintainers.tryy3 ];
  };
}
