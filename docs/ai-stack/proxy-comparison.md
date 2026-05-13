# AI Proxy — Decision: Manifest

## Why Manifest

**Project**: [mnfst/manifest](https://github.com/mnfst/manifest) | [manifest.build](https://manifest.build)
**Stars**: 6.4k | **License**: MIT | **Latest**: v6.3.0 (May 2026, active daily)
**Language**: TypeScript | **Deployment**: Docker image (`manifestdotbuild/manifest`)

Manifest is a **smart model router for agents** — it sends each query to the cheapest model that can handle it, often saving up to 70% on inference costs.

## Key Features

- **Smart routing**: Complexity-based, specificity-based, and custom HTTP header routing via `manifest/auto`
- **Provider ecosystem**:
  - **API keys**: OpenAI, Anthropic, Google, xAI, DeepSeek, Mistral, Qwen, Moonshot, MiniMax, Z.ai, OpenRouter
  - **Subscriptions** (reuse existing paid plans): OpenAI ChatGPT Plus/Pro, Anthropic Claude Max/Pro, GitHub Copilot, OpenCode Go
  - **Local models**: Ollama, LM Studio, llama.cpp
  - **Custom**: Any OpenAI-compatible or Anthropic-compatible endpoint
- **OpenAI-compatible API**: `POST http://localhost:2099/v1/chat/completions`
- **Spending controls**: Per-key limits, email alerts
- **Fallbacks**: Automatic retry on different models when queries fail
- **Dashboard**: Web UI at `http://localhost:2099` for configuration, cost tracking, provider management
- **Hermes integration**: Listed as a supported agent (hermes-agent is a GitHub topic, telemetry tracks hermes usage)
- **OpenClaw integration**: Also supported

## Self-Hosted Setup

Manifest ships as a Docker image. Quick install:

```bash
bash <(curl -sSL https://raw.githubusercontent.com/mnfst/manifest/main/docker/install.sh)
# Dashboard at http://localhost:2099
```

Requirements:
- Docker/Podman (we already have `modules/features/podman/`)
- PostgreSQL (bundled in docker-compose)
- Port 2099 (binds to 127.0.0.1 by default)

## NixOS Integration Strategy

Manifest is **not in nixpkgs**. Two integration paths:

### Option A: Podman Container (quickest)
Use our existing podman feature to run the Manifest Docker image:
- Generate `docker-compose.yml` + `.env` from Nix
- systemd service to manage `podman compose up/down`
- Sops for secrets (`BETTER_AUTH_SECRET`, API keys via Manifest dashboard)

### Option B: Flake Input + Custom Package (cleaner)
Add `mnfst/manifest` as a flake input, build the Docker image or package the Node.js app:
- `buildNpmPackage` or `dockerTools.pullImage`
- systemd service wrapping the container
- More Nix-idiomatic but more packaging effort

**Recommendation**: Start with Option A (podman) for speed, evaluate Option B later.

## Provider Strategy

| Provider | Type | Key | Purpose |
|---|---|---|---|
| OpenRouter | API key | `sk-or-...` | Primary cloud provider, 300+ models |
| OpenCode | Subscription (Go) | OAuth | Coding-focused models |
| Ollama | Local | none | Free local inference |
| LM Studio | Local | none | Alternative local runner |
| Anthropic | API key | `sk-ant-...` | Optional: direct Claude access |
| GitHub Copilot | Subscription | OAuth | Reuse existing Copilot plan |

All routed through `manifest/auto` — Manifest decides which model handles each query.

## Why Not LiteLLM

| Factor | Manifest | LiteLLM |
|---|---|---|
| Agent-native design | ✅ Built for agents (hermes, openclaw) | General proxy |
| Subscription reuse | ✅ Copilot, ChatGPT Plus, Claude Max | ❌ API keys only |
| Complexity-based routing | ✅ Automatic | Rule-based (cost/latency) |
| Built-in dashboard | ✅ Web UI with cost tracking | ❌ Requires separate setup |
| NixOS packaging | ❌ (Docker) | ✅ (in nixpkgs) |
| Provider count | 16 (300+ models) | 100+ |

The tradeoff: Manifest costs more to package (Docker) but provides better agent integration, subscription reuse (Copilot → saves money), and truly smart routing. LiteLLM was dropped in favor of Manifest's superior agent-focused design and Copilot/OpenCode subscription support.

## Why Not Portkey / RouteLLM

- **Portkey**: Enterprise-focused (11.7k stars), Node.js, guardrails, more providers. But it's overkill for personal use and packaging complexity is similar to Manifest but without the agent-native design.
- **RouteLLM**: Best ML-based routing, but uses LiteLLM internally and is focused on 2-model routing (strong vs weak). Doesn't match the multi-provider subscription-reuse model.
