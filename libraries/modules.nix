{
  api,
  attrsets,
  defaults,
  filesystem,
  lists,
  modules,
  names,
  paths,
  strings,
  types,
  ...
}: let
  exports = {
    scoped = {
      inherit
        readDirAttrs
        resolveEntrypoint
        importModule
        collectSpecs
        collectNamedSpecs
        collectUserSpecs
        getUsers
        mkEnvVars
        mkHomeUser
        importAll
        mkHomeUsers
        importModules
        importProfiles
        mkCdAliases
        mkConfigurations
        mkNixosConfigurations
        mkDarwinConfigurations
        ;
    };
    global = {
      inherit mkConfigurations;
    };
  };

  inherit (attrsets) attrNames attrValues filterAttrs foldlAttrs genAttrs mapAttrs mapAttrs' mapAttrsToList recursiveUpdate;
  inherit (filesystem) baseNameOf pathExists readDir;
  inherit (lists) asList any concatMap elem findFirst length;
  inherit (modules) nixosSystem darwinSystem;
  inherit (strings) hasPrefix hasSuffix toUpper;
  inherit (types) isAttrs isString isFunction;
  inherit (api) hosts;
  entrypoint = defaults.entrypoints.nix.main;
  candidates = defaults.entrypoints.nix.candidates;

  mkNixosConfigurations = mkConfigurations {type = "nixosConfigurations";};
  mkDarwinConfigurations = mkConfigurations {type = "darwinConfigurations";};

  mkConfigurations = {
    args ? {inherit defaults paths names;},
    class ? "nixos",
  } @ params: let
    # TODO: Validate clas is one of ["nixos" "darwin"]
    args = recursiveUpdate params (params.extraArgs or {});
    # hosts = args.api.hosts or (import paths.api {inherit defaults;});
    type =
      if class == "nixos"
      then "nixosConfigurations"
      else if class == "darwin"
      then "darwinConfigurations"
      else (throw ''mkConfigurations.class: Expected one of ["nixos" "darwin"], got ${class}'');
    builder =
      if hasPrefix "nixos" class
      then nixosSystem
      else if hasPrefix "darwin"
      then darwinSystem
      else throw "mkConfigurations.builder: Unknown type";
  in {
    ${type} = mapAttrs (_: api: let
      host = recursiveUpdate defaults.host api;
      flake =
        recursiveUpdate
        (
          recursiveUpdate
          (defaults.flake or {})
          {inputs = args.inputs or (args.extraArgs.inputs or {});}
        ) (
          recursiveUpdate
          (host.flake or {})
          {home = host.path or (host.home or (host.dots or null));}
        );
    in
      builder {
        inherit (host) system;
        modules =
          (args.modules or [])
          ++ (args.extraArgs.modules or [])
          ++ (host.modules or [])
          ++ (host.imports or []);
        specialArgs =
          {
            inherit host flake;
            inherit (flake) inputs top;
            ${names.lib} = args.${names.lib};
            inherit (args) lix; # TODO: How can this not be hardcoded, i want to inherit args.${names.lib}
          }
          // args;
      })
    hosts;
  };

  readDirAttrs = {
    base,
    ignore ? defaults.ignore,
    predicate ? null,
    includeFiles ? false,
  }:
    filterAttrs
    (name: type: let
      defaultPredicate =
        if includeFiles
        then
          type
          == "directory"
          || (type == "regular" && hasSuffix ".nix" name && name != "default.nix")
        else type == "directory";
    in
      (
        if predicate != null
        then predicate name type
        else defaultPredicate
      )
      && !(elem name ignore)
      && (
        if type == "directory"
        then any (f: pathExists (base + "/${name}/${f}")) candidates
        else true
      ))
    (readDir base);

  # find the first candidate that exists under base/name/, fall back to entrypoint
  resolveEntrypoint = {
    base,
    name,
  }:
    findFirst
    (f: pathExists (base + "/${name}/${f}"))
    entrypoint
    candidates;

  importModule = {
    args ? {},
    base,
    name,
    path ? null,
  }: let
    isDir = (readDir base).${name} == "directory";
    resolved =
      if isDir
      then
        base
        + "/${name}/${
          if path != null
          then path
          else resolveEntrypoint {inherit base name;}
        }"
      else base + "/${name}";
    imported = import resolved;
  in
    if isFunction imported
    then imported args
    else imported;

  # collect { core = [...]; home = [...]; } across all subdirs of base
  collectSpecs = {
    args,
    extraArgs ? {},
    base,
    ignore ? defaults.ignore,
    tags ? defaults.tags,
    includeFiles ? false,
    rawTag ? "core",
  }: let
    entries = readDirAttrs {inherit base ignore includeFiles;};
    specs =
      mapAttrsToList
      (name: type: let
        module = importModule {
          inherit base name;
          args =
            args
            // {
              dom = baseNameOf (toString base);
              mod = name;
            }
            // extraArgs;
        };
      in
        if type == "regular"
        then {${rawTag} = module;}
        else module)
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
    rekey ? false, # when true, rekey by spec.name instead of dir name
  }: let
    entries = readDirAttrs {inherit base ignore;};
    raw =
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
  in
    if rekey
    then
      mapAttrs' (dirName: spec: {
        name = spec.name or dirName;
        value = spec // {name = spec.name or dirName;};
      })
      raw
    else raw;

  # import all files from user.imports, each returns { core = {...}; home = {...}; }
  collectUserSpecs = {
    args,
    user,
  }:
    map
    (fn: import fn (args // {inherit user;}))
    (asList (user.imports or null));

  getUsers = declared: let
    # ── group constructor ────────────────────────────────────────────────────
    mkGroup = attrs: let
      names = attrNames attrs;
      values = mapAttrs (name: user:
        user
        // {
          inherit name;
          home = user.home or "/home/${name}";
          description = user.description or name;
        })
      attrs;
      count = length names;
    in {inherit names values count;};

    # ── filter helpers ───────────────────────────────────────────────────────

    filterByStatus = status: attrs:
      filterAttrs (_: u: (u.enable or true) == (status == "enabled")) attrs;

    filterByRole = wantedRole: attrs:
      filterAttrs (
        _: u: let
          role = u.role or "";
          isNormal = role == "" || role == "user" || role == "normal";
        in
          if wantedRole == "normal"
          then isNormal
          else role == wantedRole
      )
      attrs;

    # ── cross-cutting group index ────────────────────────────────────────────
    # byStatus and byRole are mutually enriched: each slice gets the other
    # dimension attached, so callers can do .byStatus.enabled.byRole.admin etc.

    mkStatusIndex = attrs:
      genAttrs ["enabled" "disabled"] (status: let
        subset = filterByStatus status attrs;
      in
        (mkGroup subset) // {byRole = mkRoleIndex subset;});

    mkRoleIndex = attrs:
      genAttrs ["normal" "administrator" "service" "guest"] (role: let
        subset = filterByRole role attrs;
      in
        (mkGroup subset) // {byStatus = mkStatusIndex subset;});

    # ── assemble ─────────────────────────────────────────────────────────────

    users = mapAttrs (_: u:
      {
        role = "user";
        enable = true;
      }
      // u)
    declared;
  in
    (mkGroup users)
    // {
      byStatus = mkStatusIndex users;
      byRole = mkRoleIndex users;
    };

  mkHomeUsers = host:
    mapAttrs (_: user: {
      config,
      osConfig,
      top,
      ...
    }:
      mkHomeUser {inherit user config osConfig top;})
    ((getUsers host).normal.raw);

  mkHomeUser = {
    user,
    config,
    osConfig,
    top,
  }: {
    imports =
      [
        (let
          paths = config.${top}.paths or {};
        in {
          home = {
            inherit (osConfig.system) stateVersion;
            sessionVariables = mkEnvVars "" paths;
            shellAliases = mkCdAliases paths;
          };
          programs.home-manager.enable = true;
        })
      ]
      ++ concatMap
      (spec: asList (spec.home or null))
      (collectUserSpecs user);
  };

  # modules: shared across all users
  # profiles: per-user, keyed by directory name
  importAll = args @ {
    base,
    ignore ? defaults.ignore,
    tags ? defaults.tags,
    extraArgs ? {},
    includeFiles ? false,
    kind ? "modules",
    ...
  }:
    if kind == "modules"
    then let
      specs = collectSpecs {inherit args base ignore tags extraArgs includeFiles;};
    in {
      imports = specs.core or [];
      home-manager.sharedModules = specs.home or [];
    }
    else if kind == "profiles"
    then let
      byName = collectNamedSpecs {inherit args base ignore tags extraArgs;};
    in {
      imports = concatMap (profile: asList (profile.core or null)) (attrValues byName);
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
    includeFiles ? false,
    ...
  }:
    importAll (args
      // {
        kind = "modules";
        inherit includeFiles;
      });

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
        key = toUpper "${prefix}${
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
        if isAttrs value && value ? base
        then acc // {"cd${name}" = "cd ${value.base}";}
        else acc
    ) {}
    attrs;
in
  exports
