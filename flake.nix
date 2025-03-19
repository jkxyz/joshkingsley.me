{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        packages = { default = pkgs.callPackage (import ./.) { }; };
      }) // {
        nixosConfigurations.www = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./nixos/www/configuration.nix
            ./nixos/www/hardware-configuration.nix
            ./nixos/nginx.nix
          ];
        };
      };
}
