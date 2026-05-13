{
  lib,
  stdenv,
  autoPatchelfHook,
  fetchurl,
  glibc,
  makeWrapper,
}:

let
  version = "3.12.0";
  # libstdc++.so.6 — needed by the bundled Node.js binary
  libstdcxx = stdenv.cc.cc.lib;
in
stdenv.mkDerivation rec {
  pname = "byterover-cli";
  inherit version;

  # Standalone oclif distribution from GCS — bundles Node.js v24.13.1,
  # all npm dependencies, and compiled application code in a single tarball.
  # The "stable" channel always points to the latest release; the Nix hash
  # pins the exact content for reproducibility.  Update both `version` and
  # `hash` together when upgrading.
  src = fetchurl {
    url = "https://storage.googleapis.com/brv-releases/channels/stable/brv-linux-x64.tar.gz";
    hash = "sha256-nYWf3+xmbLZiMfPMC76kDTFmWfURv+XX7S38Tb8NN8k=";
  };

  sourceRoot = "brv";

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    glibc
    libstdcxx
  ];

  # Do not strip — the bundled Node.js binary contains embedded V8 snapshot
  # data that would be destroyed by strip(1).
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    # Install the full oclif distribution (bin/, dist/, node_modules/, etc.)
    mkdir -p $out/lib/byterover-cli
    cp -r bin dist node_modules .env.production oclif.manifest.json package.json package-lock.json $out/lib/byterover-cli/

    # Ensure the bundled node binary is executable
    chmod +x $out/lib/byterover-cli/bin/node

    # Create wrapper that directly invokes the bundled node with run.js.
    # This bypasses the oclif bin/brv shell script (which does auto-update
    # redirection and dynamic node discovery — both unnecessary in Nix).
    makeWrapper $out/lib/byterover-cli/bin/node $out/bin/brv \
      --add-flags "$out/lib/byterover-cli/bin/run.js"

    runHook postInstall
  '';

  meta = {
    description = "Persistent AI memory with hierarchical context tree (brv CLI)";
    longDescription = ''
      ByteRover is a CLI tool for managing persistent, curated AI memory.
      It provides a hierarchical context tree with git-like version control,
      92-96% retrieval accuracy, and supports 20+ LLM providers.

      Key commands:
        brv              Start interactive TUI
        brv curate       Add context/knowledge to the context tree
        brv query        Query the context tree
        brv mcp          Start MCP server for AI agent integration
        brv providers    Manage LLM providers
        brv vc           Version control for context tree

      To connect to a Manifest proxy at localhost:2099:
        brv providers connect openai-compatible --base-url http://localhost:2099/v1
    '';
    homepage = "https://byterover.dev";
    license = lib.licenses.elastic20;
    mainProgram = "brv";
    platforms = [ "x86_64-linux" ];
    maintainers = [ lib.maintainers.tryy3 ];
  };
}
