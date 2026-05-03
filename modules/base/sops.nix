# modules/base/sops.nix
#
# System-level sops configuration.
# Replaces hosts/common/core/sops.nix.
{
  lib,
  inputs,
  config,
  ...
}:
let
  sopsFolder = builtins.toString inputs.nix-secrets;
  secretsFile = "${sopsFolder}/secrets.yaml";
in
{
  sops = {
    defaultSopsFile = "${secretsFile}";
    validateSopsFiles = false;
    age = {
      # Automatically import host SSH keys as age keys
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };
  };

  # Bootstrap the user's age key from sops-decrypted secrets
  sops.secrets = lib.mkMerge [
    {
      "keys/age/${config.hostSpec.username}_${config.networking.hostName}" = {
        owner = config.users.users.${config.hostSpec.username}.name;
        inherit (config.users.users.${config.hostSpec.username}) group;
        path = "${config.hostSpec.home}/.config/sops/age/keys.txt";
      };
      "passwords/${config.hostSpec.username}" = {
        sopsFile = "${sopsFolder}/secrets.yaml";
        neededForUsers = true;
      };
    }
    (lib.mkIf (config.services ? hermes-agent && config.services.hermes-agent.enable) {
      "hermes-env" = {
        sopsFile = "${sopsFolder}/secrets.yaml";
        owner = config.users.users.${config.hostSpec.username}.name;
      };
    })
  ];

  # Fix ownership of .config/sops/age directory
  system.activationScripts.sopsSetAgeKeyOwnership =
    let
      ageFolder = "${config.hostSpec.home}/.config/sops/age";
      user = config.users.users.${config.hostSpec.username}.name;
      group = config.users.users.${config.hostSpec.username}.group;
    in
    ''
      mkdir -p ${ageFolder} || true
      chown -R ${user}:${group} ${config.hostSpec.home}/.config
    '';
}
