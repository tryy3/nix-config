{ pkgs, ... }:
{
  home.packages = builtins.attrValues {
    inherit (pkgs)
      kubectl
      kubelogin-oidc # provides `kubectl oidc-login` plugin used by the kubeconfig
      talosctl
      omnictl
      ;
  };

  # kubectl config
  home.file.".kube/config".text = ''
    apiVersion: v1
    kind: Config
    clusters:
      - cluster:
          server: https://kube.omni.tryy3.dev/
        name: omni-talos-default
    contexts:
      - context:
          cluster: omni-talos-default
          namespace: default
          user: omni-talos-default-admin@tryy3.dev
        name: omni-talos-default
    current-context: omni-talos-default
    users:
      - name: omni-talos-default-admin@tryy3.dev
        user:
          exec:
            apiVersion: client.authentication.k8s.io/v1
            args:
              - oidc-login
              - get-token
              - --oidc-issuer-url=https://omni.tryy3.dev/oidc
              - --oidc-client-id=native
              - --oidc-extra-scope=cluster:talos-default
            command: kubectl
            env: null
            interactiveMode: IfAvailable
            provideClusterInfo: false
  '';

  # talosctl config
  home.file.".talos/config".text = ''
    context: default
    contexts:
      default:
        endpoints:
          - https://omni.tryy3.dev/
        auth:
          siderov1:
            identity: admin@tryy3.dev
  '';

  # omnictl config
  xdg.configFile."omni/config".text = ''
    contexts:
      default:
        url: https://omni.tryy3.dev/
        auth:
          siderov1:
            identity: admin@tryy3.dev
    context: default
  '';
}
