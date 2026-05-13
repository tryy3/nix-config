# modules/features/ai-stack/default.nix
#
# AI Stack — top-level orchestrator.
#
# Imports all ai-stack sub-modules. Hosts can import this single module or
# pick specific sub-modules for granular control:
#
#   # Everything:
#   imports = [ ../features/ai-stack ];
#
#   # Or pick what you need:
#   imports = [
#     ../features/ai-stack/hermes
#     ../features/ai-stack/proxy
#     ../features/ai-stack/memory
#   ];
#
# Each sub-module wires its own Home Manager config, so no top-level HM
# wiring is needed here.
{
  imports = [
    ./hermes
    ./proxy
    ./memory
  ];
}
