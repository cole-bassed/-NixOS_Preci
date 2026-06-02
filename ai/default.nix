{
  lib,
  pkgs,
  inputs,
  ...
} @ args:
lib.importModules (args
  // {
    inherit inputs;
    base = ./.;
    includeFiles = true;
  })
