flake: let
  path = flake.inputs.self;
  inherit (flake.libraries) forEachSystem treefmt;

  evalFor = pkgs:
    treefmt.evalModule pkgs {
      projectRootFile = "flake.nix";
      programs = {
        alejandra.enable = true;
        statix.enable = true;
      };
    };
in {
  formatter = forEachSystem (pkgs: (evalFor pkgs).config.build.wrapper);

  checks = forEachSystem (pkgs: {
    formatting = (evalFor pkgs).config.build.check path;
  });
}
