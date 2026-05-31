{lib}: let
  inherit (lib.attrsets) attrByPath setAttrByPath;
  inherit (lib.lists) toList;
  inherit (lib.options) mkEnableOption;

  mkEnable = {
    name ? null,
    mod ? null,
    description ? null,
    scope ? "core",
  }: let
    module =
      if name != null && name != ""
      then name
      else if mod != null && mod != ""
      then mod
      else null;

    description' =
      if description != null
      then description
      else if module != null
      then "Whether ${module} should be enabled ${
        if scope == "core"
        then "system-wide"
        else if scope == "home"
        then "for the user"
        else throw "Expected scope to be one of [core home], got ${scope}"
      }"
      else "Whether to enable this module";
  in {
    false = mkEnableOption description';
    true = mkEnableOption description' // {default = true;};
  };

  mkCfg = {
    config,
    path,
  }:
    attrByPath (toList path) {} config;

  mkOpt = {
    options,
    path,
  }:
    setAttrByPath (toList path) options;

  mkEnableMod = {
    mod,
    scope,
  }:
    mkEnable {inherit mod scope;};

  mkModuleArgs = {
    config,
    top,
    dom,
    mod,
    scope ? "core",
  }: let
    path = [top dom mod];
  in {
    cfg = mkCfg {inherit config path;};
    opt = options: mkOpt {inherit options path;};
    mkEnableMod = mkEnableMod {inherit mod scope;};
  };
in {
  internal = {
    inherit mkEnable mkCfg mkOpt mkEnableMod mkModuleArgs;
  };
  external = {
    inherit mkEnable mkCfg mkOpt mkModuleArgs;
  };
}
