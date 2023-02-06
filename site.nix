{ buildNpmPackage, lib, ... }:

buildNpmPackage {
  name = "site";
  src = ./site;
  npmDepsHash = "sha256-zrKQBtenBb0e28yuOdefnzktcoYEbTZaL2D12ptG/Lc=";
}
