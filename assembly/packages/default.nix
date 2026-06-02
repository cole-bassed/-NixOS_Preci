flake: let
  inherit (flake.libraries) forEachSystem;
in {
  packages = forEachSystem (pkgs: {});
  devShells = forEachSystem (pkgs: {
    default = pkgs.mkShell {
      name = flake.defaults.info.name;
      packages = with pkgs; [git sops];
    };
  });
}
