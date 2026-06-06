{
  inputs ? {},
  defaults ? {allowUnfree = true;},
}: let
  bootstrap = import ./bootstrap.nix;
  inherit (bootstrap) asListIf attrValues collectModules concatLists filterAttrs findFirst hasLib hasModules hasOverlays isNixpkgsInfrastructure isNixpkgsLike mapAttrs orEmptyAttr preferDefaultModules;

  inputs' = let
    attrs = orEmptyAttr inputs;

    classified = {
      nixpkgs = filterAttrs (_: isNixpkgsLike) attrs;
      modules = filterAttrs (_: hasModules) attrs;
      overlays = filterAttrs (_: hasOverlays) attrs;
      libraries = filterAttrs (_: hasLib) attrs;
      infrastructure = filterAttrs (_: isNixpkgsInfrastructure) attrs;
    };

    normalized = {
      nixpkgs = findFirst isNixpkgsLike attrs;
      darwin = findFirst (input: input ? darwinModules) attrs;
      home-manager = findFirst (input: input ? homeManagerModules || input ? homeModules) attrs;
      treefmt = findFirst (input: input ? formatter && input ? lib) attrs;
    };
  in {inherit classified normalized;};

  libraries = let
    named = {
      classified = mapAttrs (_: input: input.lib) inputs'.classified.libraries;
      normalized = filterAttrs (_: value: value != null) inputs'.normalized;
    };
    nixpkgs = import ./nixpkgs.nix {lib = nixpkgs.lib or {};};
  in
    nixpkgs
    // named.classified
    // named.normalized
    // {inherit nixpkgs;};

  modules = let
    collect = type: collectModules type inputs'.classified.modules;
  in {
    mkCore = type:
      if type == "nixos" || type == "darwin"
      then
        (collect type)
        ++ [{nixpkgs.config = {inherit (defaults) allowUnfree;};}]
      else throw "modules::mkCore:= unknown type '${type}'";
    home = collect "home";
  };

  overlays = let
    available =
      filterAttrs
      (_: value: value != [])
      (
        mapAttrs (
          _: input:
            asListIf (input ? overlays) (preferDefaultModules input.overlays)
        )
        inputs'.classified.overlays
      );
  in {
    inherit available;
    evaluated = concatLists (attrValues available);
  };

  packages = defaults.nixpkgs.legacyPackages;
in {
  inherit
    libraries
    modules
    overlays
    packages
    ;
  inputs = inputs';
}
