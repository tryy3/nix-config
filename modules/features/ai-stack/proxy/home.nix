# modules/features/ai-stack/proxy/home.nix
#
# Home Manager configuration for Manifest proxy via rootless Podman Quadlets.
#
# Defines two containers (manifest + postgres), a network, and a volume.
# These become user-level systemd services managed by quadlet:
#   - manifest.service       (the Manifest app)
#   - manifest-postgres.service (PostgreSQL database)
#   - manifest-net-network.service (network lifecycle)
#
# Status/logs:  systemctl --user status manifest
#               journalctl --user -u manifest
#
# NOTE: This file is always imported by the proxy NixOS module, but the
# quadlet containers are only defined when osConfig.services.manifest-proxy.enable
# is true. This is because `imports` is a special option that cannot be
# conditionally set with mkIf.
{
  config,
  osConfig,
  inputs,
  lib,
  ...
}:
let
  cfg =
    osConfig.services.manifest-proxy or {
      enable = false;
      port = 2099;
    };
  enabled = cfg.enable;
  port = toString cfg.port;
in
{
  # Always import quadlet-nix HM module — it only defines options, nothing is
  # enabled unless virtualisation.quadlet containers/networks are defined.
  imports = [
    inputs.quadlet-nix.homeManagerModules.quadlet
  ];

  virtualisation.quadlet =
    let
      # PostgreSQL connection string — uses quadlet network DNS
      # (containers on the same network resolve each other by container name)
      databaseUrl = "postgresql://manifest:manifest@manifest-postgres:5432/manifest";
    in
    lib.mkIf enabled (
      let
        inherit (config.virtualisation.quadlet) containers networks volumes;
      in
      {
        # ── Network ───────────────────────────────────────────────────────
        networks.manifest-net = {
          networkConfig = {
            driver = "bridge";
            # DNS enabled by default on custom quadlet networks
          };
        };

        # ── Volume ────────────────────────────────────────────────────────
        volumes.manifest-pgdata = { };

        # ── PostgreSQL ─────────────────────────────────────────────────────
        containers.manifest-postgres = {
          autoStart = true;

          containerConfig = {
            image = "docker.io/postgres:16-alpine";
            environments = {
              POSTGRES_USER = "manifest";
              POSTGRES_PASSWORD = "manifest";
              POSTGRES_DB = "manifest";
            };
            volumes = [
              "${volumes.manifest-pgdata.ref}:/var/lib/postgresql/data"
            ];
            networks = [ networks.manifest-net.ref ];
            healthCmd = "pg_isready -U manifest";
            healthInterval = "5s";
            healthTimeout = "3s";
            healthRetries = 5;
            noNewPrivileges = true;
            logDriver = "json-file";
          };

          serviceConfig = {
            Restart = "always";
            RestartSec = "10";
            TimeoutStartSec = "120";
          };
        };

        # ── Manifest app ──────────────────────────────────────────────────
        containers.manifest = {
          autoStart = true;

          containerConfig = {
            image = "docker.io/manifestdotbuild/manifest:latest";
            publishPorts = [ "127.0.0.1:${port}:${port}" ];
            environments = {
              DATABASE_URL = databaseUrl;
              PORT = port;
              BETTER_AUTH_URL = "http://localhost:${port}";
              OLLAMA_HOST = "http://host.containers.internal:11434";
              SEED_DATA = "false";
              NODE_ENV = "production";
              MANIFEST_TELEMETRY_DISABLED = "1";
              MANIFEST_MODE = "selfhosted";
            };
            environmentFiles = [
              osConfig.sops.templates."manifest-env".path
            ];
            networks = [ networks.manifest-net.ref ];
            # Health check — simple HTTP probe
            healthCmd = "node -e \"fetch('http://127.0.0.1:${port}/api/v1/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))\"";
            healthInterval = "30s";
            healthTimeout = "5s";
            healthStartPeriod = "90s";
            healthRetries = 3;
            # Security hardening
            dropCapabilities = [ "ALL" ];
            noNewPrivileges = true;
            readOnly = true;
            tmpfses = [ "/tmp:size=64m" ];
            # Resource limits
            memory = "1g";
            pidsLimit = 512;
            # Logging
            logDriver = "json-file";
            logOptions = [
              "max-size=10m"
              "max-file=5"
            ];
          };

          # Manifest depends on PostgreSQL being healthy
          unitConfig = {
            Requires = [ containers.manifest-postgres.ref ];
            After = [ containers.manifest-postgres.ref ];
          };

          serviceConfig = {
            Restart = "always";
            RestartSec = "10";
            # Podman needs time to pull images on first boot
            TimeoutStartSec = "300";
          };
        };
      }
    );
}
