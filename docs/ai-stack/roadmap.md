# AI Stack — Implementation Roadmap

## Phase 0: Foundation (current)

**Status**: Pre-implementation, investigation complete.

**Done**:
- [x] Investigated and selected **Manifest** (`mnfst/manifest`) as the smart proxy/router
- [x] Investigated and selected **ByteRover** (`campfirein/byterover-cli`) as the memory layer
- [x] Documented architecture, proxy comparison, and roadmap

**Remaining**:
- [ ] Create `modules/features/ai-stack/` directory structure
- [ ] Add flake inputs for Manifest and ByteRover (if packaging directly)

---

## Phase 1: Hermes Core (barebone)

**Goal**: Extract hermes from nexer-wsl hardware config into a proper feature module, enable on fw-16.

**Current state**: Hermes is configured in `hosts/nixos/nexer-wsl/hermes.nix` as a host-specific hardware config. It needs to become a proper `modules/features/ai-stack/hermes/` dendrite.

**Scope**:
1. Create `modules/features/ai-stack/hermes/default.nix`
   - Move `services.hermes-agent` config from nexer-wsl to here
   - Use `config.hostSpec` for dynamic values (username, etc.)
   - Keep existing settings for now: model defaults, toolsets, memory provider
2. Create `modules/features/ai-stack/hermes/home.nix` (HM-level)
   - hermes CLI aliases
   - Environment variables for hermes
3. Wire secrets:
   - The `hermes-env` sops secret stays in `modules/base/sops.nix`
4. Update `hosts/nixos/nexer-wsl/default.nix`:
   - Remove `./hermes.nix` import
   - Keep `inputs.hermes-agent.nixosModules.default`
5. Add to `modules/hosts/fw-16.nix`:
   - Import `../features/ai-stack/hermes`

**Deliverable**: Hermes running on fw-16 with same core config as nexer-wsl.

---

## Phase 2: Manifest Proxy/Router

**Goal**: Deploy Manifest as the smart model router, configured with all providers and complexity-based auto-routing.

**Packaging strategy**: Manifest ships as a Docker image (`manifestdotbuild/manifest`). We'll use our existing podman feature to run it as a systemd-managed container.

**Scope**:
1. Create `modules/features/ai-stack/proxy/default.nix`:
   - Generate `docker-compose.yml` + `.env` from Nix expressions
   - systemd service: `podman compose up -d` / `podman compose down`
   - Firewall: bind to 127.0.0.1:2099 (or Tailscale for VM access)
   - Sops for `BETTER_AUTH_SECRET` (session signing)
2. Create `modules/features/ai-stack/proxy/home.nix`:
   - Environment: `MANIFEST_URL=http://localhost:2099`
   - Shell alias: `mproxy` → open dashboard, `mlog` → view logs
3. Provider configuration via Manifest dashboard (not Nix):
   - OpenRouter API key (primary cloud)
   - OpenCode Go subscription (coding models)
   - Ollama local (port 11434)
   - Anthropic API key (optional direct access)
4. Point hermes at Manifest:
   - Change hermes model provider to use OpenAI-compatible API at `http://localhost:2099/v1`
   - Model: `manifest/auto` for smart routing

**Deliverable**: All AI API calls go through `localhost:2099`, with smart complexity-based routing and Copilot/OpenCode subscription reuse.

**Questions**:
- Should we also configure a "manual override" model path for when we want to pick a specific model?
- Running PostgreSQL via podman (bundled in compose) vs using a system-installed PostgreSQL?

---

## Phase 3: ByteRover Memory

**Goal**: Install and configure ByteRover CLI for persistent, curated AI memory.

**ByteRover** (campfirein/byterover-cli):
- 4.7k stars, Elastic License 2.0, v3.12.0 (active)
- CLI tool: `brv`
- npm package: `byterover-cli`
- 92-96% retrieval accuracy on LoCoMo and LongMemEval-S benchmarks
- Local-first, cloud optional
- Git-like version control for context tree
- Supports 20 LLM providers, 22+ AI coding agents
- MCP integration built in

**Scope**:
1. Package `byterover-cli` as a user package:
   - Use `buildNpmPackage` or `fetchNpmPackage` from nixpkgs
   - Or add as a flake input pointing to `github:campfirein/byterover-cli`
   - Add to `home.packages` via `modules/features/ai-stack/memory/home.nix`
2. Create `modules/features/ai-stack/memory/default.nix`:
   - No daemon needed (CLI tool)
   - Configure LLM provider for ByteRover (can reuse Manifest proxy!)
   - Optional: systemd timer for auto-curation
3. Shell integration:
   - Alias: `br` → `brv`
   - Alias: `curate` → `brv curate`
   - Alias: `memory` → `brv query`
4. Integration with Manifest:
   - ByteRover can use Manifest as its LLM provider for curation/query
   - Shared API key management through Manifest

**Deliverable**: `brv` CLI available, persistent memory tree for AI agents.

---

## Phase 4: Messaging Gateways

**Goal**: Multiple ways to interact with Hermes.

### Phase 4a — CLI Gateway (baseline)
- Hermes CLI aliases: `hq` (quick question), `hc` (chat mode), `ha` (agent mode)
- Shell integration: keybindings for quick AI access
- Bridge to ByteRover: `hq --memory` queries with ByteRover context

### Phase 4b — Discord Gateway (from nexer-wsl)
- Already configured on nexer-wsl
- Move Discord config to gateway sub-module
- Add to fw-16 with host-specific channels

### Phase 4c — MCP/ACP Gateway (future)
- Both ByteRover and Manifest have MCP support
- Enable AI tools (IDEs, other agents) to talk to Hermes
- ByteRover's `brv mcp` command starts an MCP server

### Phase 4d — Future Gateways
- Matrix bridge
- Web UI (Hermes may get this natively, or use Manifest's dashboard)
- GitHub/Discord webhooks

---

## Phase 5: Profiles & Skills

**Goal**: Hermes profiles and ByteRover knowledge curation.

### Profiles
- "coder" — software engineering, Nix-specific knowledge
- "writing" — prose, editing
- "research" — deep analysis, long-form
- "quick" — fast, concise answers

### Skills
- Nix/NixOS skill
- Git skill
- Code review skill
- Shell skill

### ByteRover Curation
- Auto-curate project knowledge on `nixos-rebuild`
- Curate Obsidian vault into ByteRover tree
- Version-controlled memory branches for different projects

---

## Phase 6: Extras

### Obsidian → Memory Bridge
- Index Obsidian vault into ByteRover context tree
- Use `brv curate -f ~/sync/obsidian-vault-01/`
- Keep obsidian feature (or move to ai-stack extras)

### LM Studio / Ollama
- Already installed as features
- Manifest can route to both via their OpenAI-compatible APIs
- LM Studio: `http://localhost:1234/v1`
- Ollama: `http://localhost:11434/v1`

### Future Extras
- **Kanban board** (Vikunja, Plane, Focalboard)
- **Langfuse** (in nixpkgs) — LLM observability
- **Open WebUI** — ChatGPT-like interface

---

## Host Wiring Plan (After All Phases)

### fw-16 (full AI workstation)
```nix
imports = [
    # ... existing ...
    ../features/ai-stack/hermes
    ../features/ai-stack/proxy        # Manifest on :2099
    ../features/ai-stack/memory       # ByteRover CLI
    ../features/ai-stack/gateway
    ../features/ai-stack/gateway/cli
    ../features/ai-stack/gateway/discord
    ../features/ai-stack/extras/obsidian
];
```

### nexer-wsl (lightweight AI access)
```nix
imports = [
    # ... existing ...
    ../features/ai-stack/hermes       # kept, existing config preserved
    # Optional: proxy (point at fw-16's Manifest via Tailscale)
    # Optional: memory (share ByteRover tree via cloud)
];
```

---

## Open Questions

1. **Proxy now or later?** Wire Manifest in Phase 1 (alongside hermes) or get hermes standalone first?
2. **Model provider unification**: Both hosts currently use `copilot` provider. Switch both to Manifest proxy, or let nexer-wsl keep its direct setup?
3. **Podman vs native packaging**: Start with podman for Manifest (quick), or build a Nix package right away (cleaner)?
4. **ByteRover packaging**: `buildNpmPackage` from nixpkgs or flake input? npm package is `byterover-cli`.
5. **VM migration**: Manifest proxy + ByteRover make sense as shared services on a VM. Hermes could remain per-host or move to server.
6. **PostgreSQL**: Manifest requires it. Use the bundled one in docker-compose, or a system-installed PostgreSQL?

---

## Dependency Map

```
Phase 1 (Hermes core)
    │
    ├──► Phase 2 (Manifest proxy) ── depends on Phase 1
    │
    ├──► Phase 3 (ByteRover) ────── can start in parallel with Phase 2
    │
    └──► Phase 4 (Gateways) ─────── depends on Phase 1
         │
         ├──► Phase 5 (Profiles) ── depends on Phase 1 + Phase 3
         │
         └──► Phase 6 (Extras) ──── mostly independent
```

Phases 2 and 3 can happen in parallel since they're independent services (Manifest is routing, ByteRover is memory).
