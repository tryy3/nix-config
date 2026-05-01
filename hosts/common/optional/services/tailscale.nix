{ config, ... }:
{
  # Auth key is read from sops; expected key path in nix-secrets/secrets.yaml:
  #
  #   tailscale:
  #       auth-key: tskey-auth-xxxxxxxxxxxx-...
  #
  # The key is read only on first `tailscale up`; persistent state in
  # /var/lib/tailscale keeps the node logged in across reboots/rebuilds,
  # so a single-use (non-reusable) key is fine.
  sops.secrets."tailscale/auth-key" = { };

  services.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets."tailscale/auth-key".path;
    openFirewall = true; # opens UDP port for direct (non-DERP) connections
    useRoutingFeatures = "client"; # plain client; flip to "both" to advertise routes/exit
    extraUpFlags = [
      "--ssh" # allow SSH into this host over the tailnet via Tailscale identity
    ];
  };

  # Trust the tailnet interface so peers reach local services without per-port rules.
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
}
