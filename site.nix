{ buildNpmPackage, lib, ... }:

buildNpmPackage {
  name = "site";
  src = ./site;
  # npmDepsHash = lib.fakeHash;
  npmDepsHash = "sha256-SIBBCkUSWPuHhxh91TBYF9YRBUOxqKeQ8vy39MvWbN8=";
}
