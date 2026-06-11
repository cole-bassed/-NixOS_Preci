{
  bootstrap ? import ./base,
  defaults ? {},
  flake ? {},
  names ? {},
  paths ? {},
}: let
  inherit (bootstrap.attrsets) merge;

  external = import ./external {
    inherit bootstrap defaults flake names paths;
  };

  internal = import ./internal {inherit bootstrap external;};
  # internal = {};
  merged = merge external (merge bootstrap internal);
in {
  # inherit external;
  lib = merged.lib or external.${names.src}.libraries.merged;
  ${names.src} = (external.${names.src} or {}) // (internal.${names.src} or {});
  ${names.lib} = removeAttrs merged ["${names.lib}"];
}
