# AI Stack (`ai-stack`)

A feature-based NixOS module that provides a full AI workstation stack: agent framework, smart model proxy, persistent memory, messaging gateways, and complementary tools.

## Vision

To have a **self-hosted, modular AI infrastructure** on my laptop (and eventually a VM/server) that:

1. **Gives me a unified AI agent** (Hermes) that I can talk to via CLI, Discord, and future gateways
2. **Smartly routes my prompts** to the right model — local (Ollama/LM Studio) or cloud (OpenRouter, OpenCode) — based on task complexity and cost, without me having to think about it
3. **Remembers context persistently** across sessions via ByteRover's curated knowledge tree, with best-in-class 92-96% retrieval accuracy
4. **Is declaratively managed** via Nix, with all API keys in sops, no manual env-var fiddling

## Component Decisions

| Layer | Choice | Rationale |
|---|---|---|
| **Agent** | Hermes (NousResearch) | Already in use on nexer-wsl, good NixOS module |
| **Proxy/Router** | [Manifest](https://manifest.build) (mnfst/manifest) | Smart complexity-based routing, Copilot/OpenCode subscription reuse, agent-native design |
| **Memory** | [ByteRover](https://byterover.dev) (campfirein/byterover-cli) | Hierarchical context tree, 92-96% retrieval accuracy, portable across agents |
| **Secrets** | sops-nix | Already in use, zero-effort integration |

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     ai-stack                             │
├─────────────────────────────────────────────────────────┤
│  Messaging Gateways                                      │
│  ┌──────────┬──────────────┬──────────────┬───────────┐ │
│  │   CLI    │   Discord    │  MCP / ACP   │  (future) │ │
│  └────┬─────┴──────┬───────┴──────┬───────┴─────┬─────┘ │
│       │            │              │             │       │
│       └────────────┼──────────────┼─────────────┘       │
│                    │              │                     │
│              ┌─────▼──────────────▼─────┐               │
│              │     Hermes Agent          │               │
│              │  (NousResearch/hermes)    │               │
│              └──────────┬───────────────┘               │
│                         │                               │
│              ┌──────────▼───────────────┐               │
│              │   Manifest Router         │               │
│              │ (mnfst/manifest, :2099)  │               │
│              │    manifest/auto          │               │
│              └──┬─────┬─────┬─────┬─────┘               │
│                 │     │     │     │                     │
│         ┌───────┘     │     │     └────────┐            │
│         ▼             ▼     ▼              ▼            │
│    ┌────────┐  ┌──────────┐ ┌────────┐ ┌──────────┐   │
│    │OpenRouter│ │OpenCode  │ │ Ollama  │ │Anthropic │   │
│    │(API key)│ │(Go sub)  │ │(local) │ │(API key) │   │
│    └────────┘  └──────────┘ └────────┘ └──────────┘   │
│                                                         │
│  Memory (ByteRover)                                     │
│  ┌────────────────────────────────────────────┐        │
│  │  ByteRover CLI (brv)                        │        │
│  │  ┌──────────────────────────────────────┐  │        │
│  │  │ Context tree (hierarchical knowledge)│  │        │
│  │  │ Version-controlled (git-like)        │  │        │
│  │  │ Local-first, cloud optional          │  │        │
│  │  └──────────────────────────────────────┘  │        │
│  └────────────────────────────────────────────┘        │
│                                                         │
│  Extras                                                 │
│  ┌───────────────┬──────────────┬──────────────────┐   │
│  │   Obsidian    │   Kanban     │   LM Studio      │   │
│  │  (note-taking)│  (future)    │  (local models)  │   │
│  └───────────────┴──────────────┴──────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

## Current State

### Existing Hermes Setup (nexer-wsl only)

- **Location**: `hosts/nixos/nexer-wsl/hermes.nix` (hardware config, not a feature module)
- **Upstream**: `github:NousResearch/hermes-agent` flake input
- **Configured**: model (`claude-sonnet-4.6` via `copilot`), memory (`holographic`), Discord gateway, all toolsets, hermes-memory-store plugin
- **Secrets**: `hermes-env` sops secret, conditionally decrypted when service enabled

### Existing Adjacent Features (fw-16)

- **lm-studio**: Installs `pkgs.unstable.lmstudio` (local LLM runner)
- **obsidian**: Installs `pkgs.unstable.obsidian` + shell alias `wiki`

## Proposed Directory Structure

```
modules/features/ai-stack/
├── default.nix              # Top-level orchestrator, imports sub-modules
├── hermes/                  # Hermes agent — barebone core
│   ├── default.nix          # services.hermes-agent enable + settings
│   ├── home.nix             # HM-level config (hermes CLI, env vars)
│   └── profiles/            # Hermes profiles (future)
├── proxy/                   # Manifest smart router
│   ├── default.nix          # Podman container / systemd service
│   └── compose/             # docker-compose + env template
├── memory/                  # ByteRover persistent memory
│   ├── default.nix          # NixOS service + HM config
│   └── home.nix             # brv CLI + shell aliases
├── gateway/                 # Messaging gateways
│   ├── default.nix
│   ├── cli.nix
│   └── discord.nix
├── skills/                  # Hermes skills (future)
│   └── default.nix
└── extras/                  # Complementary tools
    ├── default.nix
    ├── obsidian.nix
    └── kanban.nix (future)
```

## Packaging Notes

Both Manifest and ByteRover are **not in nixpkgs**. Integration strategies:

### Manifest
- **Docker image on Docker Hub**: `manifestdotbuild/manifest`
- **Strategy**: Use existing podman feature + systemd service to manage container lifecycle
- **Requires**: PostgreSQL (bundled in compose), port 2099
- **Secrets**: `BETTER_AUTH_SECRET` via sops, API keys via Manifest dashboard

### ByteRover CLI
- **npm package**: `byterover-cli`
- **Strategy**: Package via `buildNpmPackage` or `fetchNpmPackage` as a user package
- **Install**: `brv` CLI in `home.packages`
- **No daemon needed**: CLI tool runs on demand

## See Also

- [Proxy Decision](./proxy-comparison.md) — why Manifest over LiteLLM/Portkey/RouteLLM
- [Roadmap](./roadmap.md) — phased implementation plan
