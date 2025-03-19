{ buildNpmPackage, ... }:

buildNpmPackage {
  name = "joshkingsley.me";
  src = ./.;
  npmDepsHash = "sha256-Z4XMuNG2a/04PIIzVUl/nTndC3BpYS1PtIDiSM7SujY=";
}
