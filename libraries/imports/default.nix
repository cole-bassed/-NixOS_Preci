{libraries}: let
  lib = libraries.nixpkgs;
  curated = import ./nixpkgs.nix {inherit lib;}; # TODO: Split into separate files
  nixpkgs = lib // curated;
in
  libraries // {inherit nixpkgs;} // nixpkgs
