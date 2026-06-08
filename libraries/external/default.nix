{
  bootstrap ? import ../bootstrap,
  flake ? {
    defaults = {allowUnfree = true;};
    name = "dots";
    path = ../../.;
    inputs = {};
  },
}: let
  inherit (bootstrap.config) collect preferDefault getPackages;
  inherit (bootstrap.lists) asListIf concat elem;
  inherit (bootstrap.attrsets) asIf filter firstOf maps orEmpty update valuesOf;
  inherit
    (bootstrap.types)
    hasLib
    hasModules
    hasOverlays
    isFlakeLike
    isHomeManagerLike
    isNixDarwinLike
    isNixpkgsInfrastructure
    isNixpkgsLike
    isNotEmpty
    isTreefmtLike
    ;

  inherit (flake) defaults name path;

  inputs = let
    raw =
      filter
      (input: _: !(elem input ["self" (orEmpty flake.name)]))
      (orEmpty flake.inputs);

    classified = {
      nixpkgs = filter (_: isNixpkgsLike) raw;
      nix-darwin = filter (_: isNixDarwinLike) raw;
      treefmt = filter (_: isTreefmtLike) raw;

      home-manager =
        filter
        (
          input: value:
            isHomeManagerLike value
          # || input == "nixHM"
        )
        raw;

      modules =
        filter
        (
          input: value:
            hasModules value
            && !(isNixpkgsLike value)
          # && input != "nixHM"
        )
        raw;

      overlays = filter (_: hasOverlays) raw;

      packages =
        filter
        (_: value: value ? packages && !(isNixpkgsLike value))
        raw;

      libraries = filter (_: hasLib) raw;
      infrastructure = filter (_: isNixpkgsInfrastructure) raw;
    };

    normalized = {
      nixpkgs =
        if isNotEmpty (defaults.nixpkgs or {})
        then defaults.nixpkgs
        else firstOf classified.nixpkgs;

      nix-darwin = firstOf classified.nix-darwin;
      home-manager = firstOf classified.home-manager;
      treefmt = firstOf classified.treefmt;
    };
  in {inherit raw classified normalized;};

  libraries = let
    classified = (
      maps
      (_: input: input.lib)
      inputs.classified.libraries
    );

    normalized =
      (
        maps
        (_: input: input.lib)
        (
          filter
          (_: value: value != null && value ? lib)
          inputs.normalized
        )
      )
      // {
        inherit bootstrap;
        nixpkgs = import ./nixpkgs.nix inputs.normalized.nixpkgs;
      }
      // (
        asIf
        (inputs ? normalized.treefmt.lib)
        {treefmt = inputs.normalized.treefmt.lib // {inherit path;};}
      );

    merged = update classified normalized;
    default =
      normalized.nixpkgs
      // classified
      // normalized;
  in {inherit classified normalized merged default;};

  modules = let
    excludes = defaults.excludes.modules or [];

    raw =
      filter
      (input: _: !(elem input excludes))
      inputs.classified.modules;

    classified = let
      mk = type: collect type raw;
    in {
      nixos = mk "nixos";
      darwin = mk "darwin";
      home = mk "home";
    };

    normalized = {
      home-manager = type: let
        key = type:
          if type == "nixos"
          then "nixosModules"
          else if type == "darwin"
          then "darwinModules"
          else null;
        input = inputs.normalized.home-manager;
      in
        asListIf
        (
          (isNotEmpty key)
          && (isNotEmpty input) #TODO: We shoouldn't need this, `?` does this
          && input ? ${key}.home-manager
        )
        input.${key}.home-manager;
    };

    mkCore = type:
      if type == "nixos" || type == "darwin"
      then
        classified.${type}
        ++ normalized.home-manager type
        ++ [{nixpkgs.config = {inherit (defaults) allowUnfree;};}]
      else throw "external.modules.mkCore: unknown type '${type}'";
  in
    {
      inherit raw classified normalized excludes mkCore;
    }
    // classified;

  overlays = let
    excludes = defaults.excludes.overlays or [];

    raw =
      filter
      (input: _: !(elem input excludes))
      inputs.classified.overlays;

    classified =
      filter
      (_: value: value != {})
      (maps (_: input: input.overlays or {}) raw);

    normalized = {};
  in {
    inherit raw classified normalized excludes;

    all = classified // normalized;

    default =
      concat
      (map preferDefault (valuesOf classified));
  };

  packages = let
    raw = inputs.classified.packages;

    classified =
      maps
      (_: getPackages)
      raw;

    normalized =
      asIf (inputs.normalized.nixpkgs != null) {
        nixpkgs = getPackages inputs.normalized.nixpkgs;
      }
      // asIf (inputs.normalized.home-manager != null) {
        home-manager = getPackages inputs.normalized.home-manager;
      };
  in {
    inherit raw classified normalized;

    all = classified // normalized;
    default = orEmpty normalized.nixpkgs;
  };
in
  libraries.default
  // asIf (isFlakeLike inputs) {
    ${name} = {
      inherit
        defaults
        inputs
        libraries
        modules
        name
        overlays
        packages
        path
        ;

      # inherit
      #   (inputs.normalized)
      #   treefmt
      #   nixpkgs
      #   nix-darwin
      #   home-manager
      #   ;
    };
  }
