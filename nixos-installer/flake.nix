{
  description = "Minimal NixOS configuration for bootstrapping systems";

  inputs = {
    # FIXME(starter): adjust nixos version for the minimal environment as desired.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    disko.url = "github:nix-community/disko";
  };

  outputs = {...}: {
    nixosConfigurations = {};
  };
}
