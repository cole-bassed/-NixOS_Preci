lib: let
  path = flake.inputs.self;
  inherit (lib.treefmt) evalModule;
  inherit (lib.config) forEachSystem;

  evalFor = pkgs:
    evalModule pkgs {
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
