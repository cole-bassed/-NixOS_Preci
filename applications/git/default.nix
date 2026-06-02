{
  top,
  lib,
  pkgs,
  dom,
  mod,
  ...
} @ args: let
  inherit (lib.lists) concatMap asList;
  inherit (lib.options) mkModuleArgs;

  mkArgs = {
    config,
    scope,
  }:
    mkModuleArgs {inherit config top dom mod scope;};

  packages = with pkgs; {
    inherit git delta gitui git-lfs gh jujutsu;
  };

  subArgs = args // {inherit packages mkArgs;};

  collect = tag:
    concatMap (spec: asList (spec.${tag} or null))
    (map (f: import f subArgs) [
      ./git.nix
      ./lfs.nix
      ./delta.nix
      ./gitui.nix
      ./gh.nix
      ./jj.nix
      ./profiles.nix
    ]);
in {
  core = collect "core";
  home = collect "home";
}
