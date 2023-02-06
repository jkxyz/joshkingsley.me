{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        packages = { site = pkgs.callPackage (import ./site.nix) { }; };
      }) // {
        nixosConfigurations.www = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./www/configuration.nix
            ./www/hardware-configuration.nix
            ./www/nginx.nix
          ];
        };
      };
}
