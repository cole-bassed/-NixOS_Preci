# flake: let
#   path = flake.inputs.self;
#   inherit (flake.libraries) forEachSystem mkConfigurations treefmt;
# in
#   (import ./formatting.nix {inherit forEachSystem treefmt path;})
#   // (mkConfigurations {
#     class = "nixos";
#     args = flake;
#   })
# assembly/default.nix
flake:
{}
// import ./configurations flake
// import ./packages flake
// import ./templates flake
// import ./utilities flake
