{
  lib,
  stdenv,
  autoPatchelfHook,
  glibc,
  fetchurl,
  nodejs,
  makeWrapper,
}: let
  version = "0.10.0";
  # Pre-built platform-specific binary from https://github.com/modem-dev/hunk/releases
  # This is a Bun-compiled standalone binary that the npm wrapper delegates to.
  # IMPORTANT: Do not strip this binary — stripping removes the embedded Bun
  # application data and breaks the executable.
  platformBinary =
    if stdenv.hostPlatform.system == "x86_64-linux"
    then
      fetchurl {
        url = "https://github.com/modem-dev/hunk/releases/download/v${version}/hunkdiff-linux-x64.tar.gz";
        hash = "sha256-ND3Kb1u0B5O+joNCvE4LzJjYpSFnt5QWDFGmuAmYns8=";
      }
    else throw "hunkdiff: unsupported system: ${stdenv.hostPlatform.system}";

  # The npm package containing the CLI entry point and skill files
  npmPkg = fetchurl {
    url = "https://registry.npmjs.org/hunkdiff/-/hunkdiff-${version}.tgz";
    hash = "sha256-wOp9cLyfE6PM+KLhxp8v1NOuGQ4Y+RygHIGdBdqTthY=";
  };
in
  stdenv.mkDerivation rec {
    pname = "hunkdiff";
    inherit version;

    src = npmPkg;

    nativeBuildInputs = [
      autoPatchelfHook
      makeWrapper
    ];

    buildInputs = [glibc];

    setSourceRoot = "sourceRoot=package";

    # Do not strip the binary — it contains embedded Bun application data
    dontStrip = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/hunkdiff $out/bin

      # Install the npm package files
      cp -r bin skills LICENSE README.md package.json $out/lib/hunkdiff/

      # Unpack and install the platform-specific binary
      # The release tarball structure is: hunkdiff-linux-x64/hunk
      mkdir -p $out/lib/hunkdiff/node_modules/hunkdiff-linux-x64/bin
      tar xzf ${platformBinary} --strip-components=1 \
        -C $out/lib/hunkdiff/node_modules/hunkdiff-linux-x64 \
        hunkdiff-linux-x64/hunk
      mv $out/lib/hunkdiff/node_modules/hunkdiff-linux-x64/hunk \
         $out/lib/hunkdiff/node_modules/hunkdiff-linux-x64/bin/hunk
      chmod +x $out/lib/hunkdiff/node_modules/hunkdiff-linux-x64/bin/hunk

      # Create wrapper that runs the hunk.cjs entry point with node
      makeWrapper ${lib.getExe nodejs} $out/bin/hunk \
        --add-flags "$out/lib/hunkdiff/bin/hunk.cjs" \
        --prefix PATH : ${lib.makeBinPath [nodejs]}
      runHook postInstall
    '';

    meta = {
      description = "Review-first terminal diff viewer for agentic coders";
      homepage = "https://github.com/modem-dev/hunk";
      license = lib.licenses.mit;
      mainProgram = "hunk";
      platforms = ["x86_64-linux"];
      maintainers = [lib.maintainers.tryy3];
    };
  }
