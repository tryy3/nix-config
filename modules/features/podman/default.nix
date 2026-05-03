{
  virtualisation.podman = {
    enable = true;
    # Create a `docker` alias so tools expecting the docker CLI work transparently
    dockerCompat = true;
    # Required for containers to be able to talk to each other on a user-defined network
    defaultNetwork.settings.dns_enabled = true;
  };

  # Default OCI registries searched when a short image name is used (e.g. `podman pull nginx`)
  virtualisation.containers.registries.search = [
    "docker.io"
    "ghcr.io"
    "quay.io"
  ];
}
