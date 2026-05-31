{
  lib,
  inputs,
  defaults,
}: let
  exports = {
    internal = {inherit mkNix mkNixConfigurations;};
    external = {inherit mkNixConfigurations;};
  };

  inherit (lib.attrsets) mapAttrs;

  mkNix = {
    dots ? defaults.dots,
    extraArgs ? {},
    modules ? defaults.modules,
    system ? defaults.system,
    top ? defaults.top,
  }:
    lib.nixosSystem {
      inherit modules system;
      specialArgs = {inherit inputs dots top;} // extraArgs;
    };

  mkNixConfigurations = {
    api,
    extraArgs ? {},
  }: {
    nixosConfigurations = mapAttrs (hostName: host:
      mkNix {
        system = host.system or defaults.system;
        dots = host.dots or defaults.dots;
        modules = host.modules or defaults.modules;
        extraArgs = {inherit host;} // extraArgs;
      })
    api.hosts;
  };
in
  exports
