{
  flake,
  names,
  defaults,
  paths,
  name ? names.lib,
  libraries ? flake.libraries or {},
  ...
}: let
  external = import ./external {inherit libraries;};
  internal = import ./internal {inherit flake names defaults paths name external;};
in
  {
    lib = external;
    "${name}" = internal;
  }
  // external
  // internal
