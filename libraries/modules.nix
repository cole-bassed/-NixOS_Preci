{
  lib,
  defaults,
  lists,
  predicates,
}: let
  exports = {
    internal = {
      inherit
        readDirAttrs
        resolveEntrypoint
        importModule
        collectSpecs
        collectNamedSpecs
        mkEnvVars
        mkHomeUser
        importAll
        importModules
        importProfiles
        mkCdAliases
        ;
    };
    external = {
      inherit
        mkEnvVars
        mkHomeUser
        collectSpecs
        collectNamedSpecs
        importAll
        importModules
        importProfiles
        ;
    };
  };

  inherit (lib.attrsets) filterAttrs foldlAttrs genAttrs mapAttrs mapAttrsToList;
  inherit (lib.filesystem0) baseNameOf readDir;
  inherit (lib.lists) concatMap elem findFirst;
  inherit (lists) asList;
  inherit (predicates) isAttrs isString;

  entrypoint = defaults.entrypoints.nix.main;
  candidates = defaults.entrypoints.nix.candidates;

  readDirAttrs = {
    base,
    ignore ? defaults.ignore,
    predicate ? (name: type: type == "directory"),
  }:
    filterAttrs
    (name: type: predicate name type && !(elem name ignore))
    (readDir base);

  # find the first candidate that exists under base/name/, fall back to entrypoint
  resolveEntrypoint = {
    base,
    name,
  }:
    findFirst
    (f: builtins.pathExists (base + "/${name}/${f}"))
    entrypoint
    candidates;

  importModule = {
    args ? {},
    base,
    name,
    path ? resolveEntrypoint {inherit base name;},
  }:
    import (base + "/${name}/${path}") args;

  # collect { core = [...]; home = [...]; } across all subdirs of base
  collectSpecs = {
    args,
    extraArgs ? {},
    base,
    ignore ? defaults.ignore,
    tags ? defaults.tags,
  }: let
    entries = readDirAttrs {inherit base ignore;};
    specs =
      mapAttrsToList
      (name: _:
        importModule {
          inherit base name;
          args =
            args
            // {
              dom = baseNameOf (toString base);
              mod = name;
            }
            // extraArgs;
        })
      entries;
  in
    genAttrs tags (tag: concatMap (spec: asList (spec.${tag} or null)) specs);

  # collect { <name> = { core = [...]; home = [...]; }; } keyed by subdir name
  # used by profiles so we know which home belongs to which user
  collectNamedSpecs = {
    args,
    extraArgs ? {},
    base,
    ignore ? defaults.ignore,
    tags ? defaults.tags,
  }: let
    entries = readDirAttrs {inherit base ignore;};
  in
    mapAttrs
    (name: _:
      importModule {
        inherit base name;
        args =
          args
          // {
            dom = baseNameOf (toString base);
            mod = name;
          }
          // extraArgs;
      })
    entries;

  # wrap a profile's home spec into a proper home-manager user import
  mkHomeUser = {
    config,
    name,
    profile,
  }: {
    imports =
      [
        {
          home.stateVersion = config.system.stateVersion;
          programs.home-manager.enable = true;
        }
      ]
      ++ (asList (profile.home or null));
  };

  # modules: shared across all users
  # profiles: per-user, keyed by directory name
  importAll = args @ {
    base,
    ignore ? defaults.ignore,
    tags ? defaults.tags,
    extraArgs ? {},
    kind ? "modules",
    ...
  }:
    if kind == "modules"
    then let
      specs = collectSpecs {inherit args base ignore tags extraArgs;};
    in {
      imports = specs.core or [];
      home-manager.sharedModules = specs.home or [];
    }
    else if kind == "profiles"
    then let
      # named so we can wire home to the right user
      byName = collectNamedSpecs {inherit args base ignore tags extraArgs;};
    in {
      # all core specs merged as system imports
      imports = concatMap (profile: asList (profile.core or null)) (builtins.attrValues byName);
      # each user gets their own home-manager config
      home-manager.users =
        mapAttrs (
          name: profile: {config, ...}: mkHomeUser {inherit config name profile;}
        )
        byName;
    }
    else throw "Expected kind to be one of [modules profiles], got ${kind}";

  # convenience: importModules is importAll with kind = "modules"
  importModules = args @ {
    base,
    ignore ? defaults.ignore,
    tags ? defaults.tags,
    extraArgs ? {},
    ...
  }:
    importAll (args // {kind = "modules";});

  # convenience: importProfiles is importAll with kind = "profiles"
  importProfiles = args @ {
    base,
    ignore ? defaults.ignore,
    tags ? defaults.tags,
    extraArgs ? {},
    ...
  }:
    importAll (args // {kind = "profiles";});

  # flatten paths attrset into env vars
  # { pictures = { base = "/home/craole/Pictures"; }; }
  # → PICTURES="/home/craole/Pictures"
  mkEnvVars = prefix: attrs:
    foldlAttrs (
      acc: name: value: let
        key = lib.strings.toUpper "${prefix}${
          if prefix == ""
          then name
          else "_${name}"
        }";
      in
        if isAttrs value && value ? base
        then acc // {"${key}" = value.base;} // mkEnvVars key value
        else if isString value
        then acc // {"${key}" = value;}
        else acc
    ) {}
    attrs;

  # generate `cd` aliases from paths
  # { pictures.base = "/home/craole/Pictures"; }
  # → pics = "cd /home/craole/Pictures"
  mkCdAliases = attrs:
    foldlAttrs (
      acc: name: value:
        if builtins.isAttrs value && value ? base
        then acc // {"cd${name}" = "cd ${value.base}";}
        else acc
    ) {}
    attrs;
in
  exports
