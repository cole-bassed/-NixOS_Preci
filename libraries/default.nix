{
  bootstrap ? import ./bootstrap,
  defaults ? {},
  flake ? {},
  name ? names.lib,
  names ? {
    src = "dots";
    lib = "lix";
    top = "_";
  },
  paths ? {src = ../.;},
}: let
  external = import ./external {
    inherit bootstrap;
    flake =
      bootstrap.recursiveUpdate {
        name = names.src;
        path = paths.src;
      }
      flake;
  };
  internal = import ./internal {inherit bootstrap external names defaults paths name;};
in
  {inherit bootstrap external internal;}
  // bootstrap.attrsets.update external internal
