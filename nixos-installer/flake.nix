{
  description = "Minimal NixOS configuration for bootstrapping systems";

  inputs = {
    # FIXME(starter): adjust nixos version for the minimal environment as desired.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    disko.url = "github:nix-community/disko"; # Declarative partitioning and formatting
  };

  # outputs = {
  #   self,
  #   nixpkgs,
  #   ...
  # }# @ inputs: {
  # nixosConfigurations = {
  # To add a host, uncomment and customize:
  #
  #   newConfig = name: disk: swapSize:
  #     nixpkgs.lib.nixosSystem {
  #       system = "x86_64-linux";
  #       specialArgs = {
  #         inherit inputs;
  #         lib = nixpkgs.lib.extend (self: super: {
  #           custom = import ../lib { inherit (nixpkgs) lib; };
  #         });
  #       };
  #       modules = [
  #         inputs.disko.nixosModules.disko
  #         ./disks/btrfs-disk.nix
  #         { _module.args = { inherit disk; withSwap = swapSize > 0; swapSize = builtins.toString swapSize; }; }
  #         ./minimal-configuration.nix
  #         ../hosts/nixos/${name}/hardware-configuration.nix
  #         { networking.hostName = name; }
  #       ];
  #     };
  #
  #   hostname1 = newConfig "hostname1" "/dev/nvme0n1" 16;
  #   };
  # };
}
