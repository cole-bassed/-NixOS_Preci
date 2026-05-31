{
  lix,
  top,
  lib,
  pkgs,
  dom,
  mod,
  ...
} @ args: let
  inherit (lib.lists) concatMap;
  inherit (lix) asList mkModuleArgs;

  mkArgs = {
    config,
    scope,
  }:
    mkModuleArgs {inherit config top dom mod scope;};

  packages = {
    ${mod} = pkgs.git;
    delta = pkgs.delta;
    gitui = pkgs.gitui;
    lfs = pkgs.git-lfs;
    gh = pkgs.gh;
    jujutsu = pkgs.jujutsu;
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
