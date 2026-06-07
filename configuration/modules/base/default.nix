# {
#   lix,
#   pkgs,
#   ...
# } @ args:
# lix.importModules (args
#   // {
#     inherit pkgs;
#     base = ./.;
#     includeFiles = true;
#   })
{
  imports = [./localization.nix];
}
