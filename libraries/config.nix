{
  api,
  debug,
  attrsets,
  defaults,
  lists,
  modules,
  types,
  ...
}: let
  exports = {
    scoped = {inherit build resolve systemBuilder systemType;};
    global = {
      resolveFlakeConfig = resolve;
      mkConfigurations = build;
    };
  };

  inherit (api) hosts;
  inherit (attrsets) mapAttrs optionalAttrs recursiveUpdate;
  inherit (debug) withContext;
  inherit (lists) elem;
  inherit (modules) nixosSystem darwinSystem;
  inherit (types) isString typeOf isAttrs isNull;

  build = {
    args ? null,
    class ? "nixos",
  }:
    assert withContext {
      name = "config.build";
      assertion = isString class;
      message = "class must be a string, got ${typeOf class}";
      context = "validating class type in build";
    };
    assert withContext {
      name = "config.build";
      assertion = isNull args || isAttrs args;
      message = "args must be an attribute set or null, got ${typeOf args}";
      context = "validating args type in build";
    }; let
      type = systemType class;
      builder = systemBuilder class;
      hosts = resolve args;
    in {${type} = mapAttrs (_: host: builder host) hosts;};

  systemBuilder = class:
    assert withContext {
      name = "config.systemBuilder";
      assertion = elem class ["nixos" "darwin"];
      message = ''expected one of ["nixos" "darwin"], got ${class}'';
      context = "parsing builder type from class";
    };
      if class == "nixos"
      then nixosSystem
      else darwinSystem;

  systemType = class:
    assert withContext {
      name = "config.systemType";
      assertion = elem class ["nixos" "darwin"];
      message = ''expected one of ["nixos" "darwin"], got ${class}'';
      context = "parsing type of config from class for config.mkConfigurations";
    };
      if class == "darwin"
      then "darwinConfigurations"
      else "nixosConfigurations";

  resolve = value: let
    args =
      recursiveUpdate
      defaults
      (optionalAttrs (isAttrs value) value);
  in
    mapAttrs (_: spec: let
      host = recursiveUpdate defaults.host spec;
      lib = args.lib or (args.libraries or {});

      flake =
        recursiveUpdate (defaults.flake or {}) (host.flake or {})
        // {
          inputs = args.inputs or (args.extraArgs.inputs or {});
          home = host.path or (host.home or (host.dots or null));
        };
    in {
      inherit (host) system;
      modules =
        (args.modules or [])
        ++ (args.extraArgs.modules or [])
        ++ (host.modules or [])
        ++ (host.imports or []);
      specialArgs =
        {
          inherit host flake lib;
          inherit (flake) inputs top;
          "${args.names.lib}" = lib;
        }
        // removeAttrs args ["modules"];
    })
    hosts;
in
  exports
