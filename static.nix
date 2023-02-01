{ buildNpmPackage, ... }:

buildNpmPackage {
  name = "joshkingsley.me";
  src = ./.;
  npmDepsHash = "sha256-INxapjIHUoEviqJgHkfe6nhHNCSiBwQsiVNCkMQwPIc=";
}
