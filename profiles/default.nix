{lib, ...}: let
  # TODO: These are clearly candidates for lib
  inherit
    (lib.attrsets)
    attrNames
    filterAttrs
    genAttrs
    mapAttrsToList
    optionalAttrs
    ;
  inherit (lib.filesystem) pathIsRegularFile readDir;
  inherit (lib.lists) elem filter findFirst;

  base = ./.;
  ignore = [
    "archive"
    "backup"
    "review"
    "temp"
  ];

  getPath = app: path: base + "/${app}/${path}";
  isAllowedDir = name: type: type == "directory" && !(elem name ignore);
  users = filterAttrs isAllowedDir (readDir base);

  findNix = root: stem:
    findFirst pathIsRegularFile null [
      (getPath root "${stem}.nix")
      (getPath root "${stem}/default.nix")
    ];

  mkUserConfig = user: let
    default = getPath user "default.nix";
    core = findNix user "core";
    home = findNix user "home";
    flat =
      if core == null && home == null && pathIsRegularFile default
      then default
      else null;
  in {
    inherit core;
    home =
      if home != null
      then home
      else flat;
  };

  modulesFor = getUserConfig:
    filter
    (module: module != null)
    (
      mapAttrsToList
      (user: _: getUserConfig (mkUserConfig user))
      users
    );
in {
  imports = modulesFor (configs: configs.core);

  home-manager.users = genAttrs (attrNames users) (
    user: let
      cfg = mkUserConfig user;
    in
      optionalAttrs (cfg.home != null) import cfg.home
  );
}
