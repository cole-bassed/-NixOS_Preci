{
  lib,
  pkgs,
  ...
} @ args:
lib.importModules (args
  // {
    inherit pkgs;
    base = ./.;
    includeFiles = true;
  })
