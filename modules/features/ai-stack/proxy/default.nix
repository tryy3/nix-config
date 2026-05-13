# modules/features/ai-stack/proxy/default.nix
#
# Manifest smart model router — self-hosted via rootless Podman Quadlets.
#
# Runs the official Manifest Docker image (manifestdotbuild/manifest) alongside
# a bundled PostgreSQL as separate Quadlet containers under the user's systemd.
# Exposes the dashboard at http://localhost:2099 and an OpenAI-compatible API
# at http://localhost:2099/v1.
#
# Provider API keys and subscription auth are configured through the Manifest
# web dashboard — not managed here. Only BETTER_AUTH_SECRET (session signing)
# is handled via sops.
#
# Architecture:
#   - NixOS level: sops secrets, quadlet enable, user linger/subuid
#   - Home Manager level (home.nix): quadlet container/network/volume definitions
#
# NOTE: Dynamic attribute names (e.g. `users.users.${username}`) must be
# defined as a SINGLE attribute set per top-level path per module. Writing
# `users.users.${username}.linger` and `users.users.${username}.autoSubUidGidRange`
# as two separate lines creates two definitions of the dynamic key, which the
# NixOS module system cannot merge within the same module.
{
  config,
  lib,
  ...
}:
let
  cfg = config.services.manifest-proxy;
  username = config.hostSpec.username;
in
{
  options.services.manifest-proxy = {
    enable = lib.mkEnableOption "Manifest AI proxy (smart model router)";
    port = lib.mkOption {
      type = lib.types.int;
      default = 2099;
      description = "Port for the Manifest dashboard and API";
    };
  };

  config = lib.mkIf cfg.enable {
    # ── Quadlet (NixOS level) ──────────────────────────────────────────
    # Required for rootless quadlet: enables podman + systemd generator
    virtualisation.quadlet.enable = true;

    # ── User setup for rootless Podman ──────────────────────────────────
    # Single definition to avoid "dynamic attribute already defined" error.
    # Linger ensures user systemd starts at boot (before login).
    # autoSubUidGidRange allocates subordinate UID/GID ranges for userns.
    users.users.${username} = {
      linger = true;
      autoSubUidGidRange = true;
    };

    # ── Secrets ──────────────────────────────────────────────────────────
    # Secret owned by the user (not root) so rootless systemd can read it
    sops.secrets."manifest-better-auth-secret" = {
      owner = config.users.users.${username}.name;
      inherit (config.users.users.${username}) group;
    };

    # Env template for the secret — readable by the user's systemd service
    sops.templates."manifest-env" = {
      owner = config.users.users.${username}.name;
      inherit (config.users.users.${username}) group;
      content = ''
        BETTER_AUTH_SECRET=${config.sops.placeholder."manifest-better-auth-secret"}
      '';
    };

    # ── Wire Home Manager config ────────────────────────────────────────
    # NOTE: imports is a special option processed before merging, so mkIf
    # cannot be used here. The home.nix file itself checks osConfig to
    # conditionally enable quadlet containers.
    home-manager.users.${username}.imports = [ ./home.nix ];
  };
}
