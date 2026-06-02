# {
#   lib,
#   pkgs,
#   ...
# } @ args:
# lib.importModules (args
#   // {
#     inherit pkgs;
#     base = ./.;
#     includeFiles = true;
#   })
{inputs, ...}: let
  modules = {
    core = with inputs; [
      hermes-agent.nixosModules.default
      home-manager.nixosModules.home-manager
      niri.nixosModules.niri
      noctalia.nixosModules.default
      sops-nix.nixosModules.default
      stylix.nixosModules.stylix
    ];

    home = with inputs; [
      niri.homeModules.config
      niri.homeModules.niri
      niri.homeModules.stylix
      noctalia.homeModules.default
      sops-nix.homeModules.default
      stylix.homeManagerModules.stylix
      vicinae.homeManagerModules.default
      zen-browser.homeModules.default
    ];
  };
in {}
