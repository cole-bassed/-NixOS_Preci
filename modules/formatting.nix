{
  nixpkgs,
  treefmt,
  ...
}: let
  supportedSystems = ["x86_64-linux" "aarch64-linux"];
  eachSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f nixpkgs.legacyPackages.${system});
in {
  # Exposes the repository code formatter engine directly to the Flake schema
  formatter = eachSystem (pkgs:
    (treefmt.lib.evalModule pkgs {
      projectRootFile = "flake.nix";

      programs = {
        nixfmt.enable = true; # Leverages your global nixpkgs formatting style
        # deadnix.enable = true; # Automatically searches and strips unused lets/variables
        statix.enable = true; # Lints code layouts and fixes common anti-patterns
      };
    }).config.build.wrapper);
}
