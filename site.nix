{ buildNpmPackage, ... }:

buildNpmPackage {
  name = "site";
  src = ./site;
  npmDepsHash = "sha256-INxapjIHUoEviqJgHkfe6nhHNCSiBwQsiVNCkMQwPIc=";
}
