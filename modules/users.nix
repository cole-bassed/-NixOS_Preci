# modules/users/default.nix
{
  inputs,
  host,
  top,
  lib,
  lix,
  ...
}: let
  inherit (lib.attrsets) attrValues mapAttrs filterAttrs;
  inherit (lib.lists) concatMap filter;
  inherit (lix.lists) asList;
  inherit (lix.modules) mkEnvVars mkCdAliases;

  users = host.users;
  normalUsers =
    filterAttrs (
      _: user:
        (user.role or "") != "service" && (user.enable or true)
    )
    users;

  # import all files from user.imports, each returns { core = {...}; home = {...}; }
  collectUserSpecs = user:
    map
    (fn:
      import fn {inherit user top host inputs lix lib;})
    (asList (user.imports or null));
in {
  imports =
    [inputs.home-manager.nixosModules.home-manager]
    # merge core specs from all normal users into system imports
    ++ concatMap
    (user: concatMap (spec: asList (spec.core or null)) (collectUserSpecs user))
    (attrValues normalUsers);

  users.users =
    mapAttrs (_: user: {
      inherit (user) description;
      isNormalUser = (user.role or "") != "service";
      autoLogin = user.autoLogin or false;
      extraGroups =
        if user.role == "administrator"
        then ["networkmanager" "wheel"]
        else if user.role == "service"
        then ["networkmanager"]
        else [];
    })
    users;

  security.sudo = {
    execWheelOnly = true;
    extraRules =
      map (user: {
        users = [user.name];
        commands = [
          {
            command = "ALL";
            options = ["SETENV" "NOPASSWD"];
          }
        ];
      })
      (filter (user: user.role == "administrator") (attrValues users));
  };

  home-manager = {
    backupFileExtension = "BaC";
    extraSpecialArgs = {inherit inputs lix top host;};
    useGlobalPkgs = true;
    useUserPackages = true;

    users =
      mapAttrs (_: user: {
        config,
        osConfig,
        ...
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
          # merge home specs from this user's imports
          ++ concatMap
          (spec: asList (spec.home or null))
          (collectUserSpecs user);
      })
      normalUsers;
  };
}
