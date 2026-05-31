# libraries/default.nix
#
# Assembles all libs in dependency order.
#
# Each lib has the shape:
#   { internal = { ... }; external = { ... }; }
#
#   internal → used here when wiring deps between libs
#             → becomes lix.<libname> (so lix.lists.nthOr, lix.lists.atOr)
#   external → collision-checked and promoted to flat lix.* namespace
#             → so lix.valueInList, lix.mkNix, etc.
#
# Usage in flake:
#   lix = import ./libraries { inherit inputs lib defaults; };
#
{
  inputs,
  lib,
  defaults,
}: let
  inherit (lib.lists) foldl';

  # ── 1. assemble in dependency order ───────────────────────────────────────

  predicates = import ./predicates.nix {inherit lib;};
  lists = import ./lists.nix {inherit lib;};
  debug = import ./debug.nix {inherit lib;};
  options = import ./options.nix {inherit lib defaults;};

  strings = import ./strings.nix {
    inherit lib;
    debug = debug.internal;
    predicates = predicates.internal;
  };
  attrsets = import ./attrsets.nix {
    inherit lib;
    lists = lists.internal;
  };
  modules = import ./modules.nix {
    inherit lib defaults;
    lists = lists.internal;
    predicates = predicates.internal;
  };
  system = import ./system.nix {
    inherit lib inputs defaults;
    modules = modules.internal;
  };

  # ── 2. namespaced surface: lix.<libname> = lib.internal ───────────────────

  namespaced = {
    lists = lists.internal;
    debug = debug.internal;
    predicates = predicates.internal;
    strings = strings.internal;
    attrsets = attrsets.internal;
    options = options.internal;
    modules = modules.internal;
    system = system.internal;
  };

  # ── 3. flat surface: collision-checked merge of all external aliases ───────

  allLibs = [
    {
      name = "lists";
      value = lists;
    }
    {
      name = "debug";
      value = debug;
    }
    {
      name = "predicates";
      value = predicates;
    }
    {
      name = "strings";
      value = strings;
    }
    {
      name = "attrsets";
      value = attrsets;
    }
    {
      name = "options";
      value = options;
    }
    {
      name = "modules";
      value = modules;
    }
    {
      name = "system";
      value = system;
    }
  ];

  externalAliases =
    foldl'
    (acc: entry: let
      incoming = entry.value.external or {};
      collisions = builtins.filter (k: builtins.hasAttr k acc) (builtins.attrNames incoming);
    in
      if collisions != []
      then
        throw ''
          libraries: external alias collision(s) detected in '${entry.name}':
            ${builtins.concatStringsSep ", " collisions}
          Each name in external must be unique across all libs.
        ''
      else acc // incoming)
    {}
    allLibs;
  # ── 4. final surface: flat aliases + namespaced (namespaced wins on clash) ─
in
  externalAliases // namespaced
