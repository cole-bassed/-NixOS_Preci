{
  bootstrap ? import ./base,
  external ? import ../external {},
  paths,
  defaults,
  names,
}: let
  inherit (bootstrap.attrsets) gets maps merge;
  flake = external.flake or {};
  name = args.names.lib;
  args = {
    inherit bootstrap;
    defaults = merge (merge defaults {
      host = "ExampleHost";
      excludes = {
        paths = [
          "archive"
          "backup"
          "review"
          "temp"

          "default.nix"
          "flake.nix"
        ];
      };

      tags = ["core" "home"];
    }) (flake.defaults or {});

    paths = merge paths (merge {
      store = {
        src = ../../.;
        api = ../../configuration/api;
      };
      local.src = "/etc/nixos";
    } (flake.paths or {}));

    names = merge names (merge {
      src = "dots";
      lib = "lix";
      top = "_";
    } (flake.names or {}));
  };

  scoped =
    maps
    (_: library: (library.scoped or {}) // (library.global or {}))
    libraries;

  global = scoped.attrsets.mergeUnique {
    owner = library: "${name}.${library}.global";
    what = "libraries";
    items = libraries;
    attrs = library:
      libraries.${library}.global or (libraries.${library} or {});
  };

  base =
    merge
    (merge external bootstrap)
    {
      inherit (args) defaults names paths;
      inherit flake libraries external;
    };

  mkLib = includes: merge base (gets includes scoped);

  libraries = {
    assembly = import ./assembly.nix (mkLib [
      "attrsets"
      "modules"
      "lists"
    ]);

    # config = import ./config (mkLib [
    #   "api"
    #   "debug"
    #   "modules"
    #   "filesystem"
    #   "lists"
    #   "types"
    # ]);

    modules = import ./modules.nix (mkLib [
      "debug"
      "filesystem"
      "lists"
      "types"
    ]);

    options = import ./options.nix (mkLib [
      "debug"
      "lists"
      "types"
    ]);

    strings = import ./strings.nix (mkLib [
      "debug"
      "lists"
      "types"
    ]);

    types = import ./types.nix (mkLib [
      "debug"
    ]);
  };

  merged = merge base (
    global
    // scoped
    // {
      lib = external;

      "${name}" = merge external (
        global
        // scoped
        // {inherit global scoped;}
      );
    }
  );
in
  merged
