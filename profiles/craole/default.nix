{
  lix,
  top,
  pkgs,
  lib,
  dom,
  mod,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lix) mkModuleArgs;

  mk = scope: {config, ...}: let
    _ = mkModuleArgs {inherit config top dom mod scope;};
    inherit (_) cfg opt mkEnable;
  in {
    options = opt {enable = mkEnable.true;};
    config = mkIf cfg.enable (
      if scope == "core"
      then {environment.systemPackages = [pkgs.${mod}];}
      else {programs.${mod}.enable = true;}
    );
  };
in {
  core = mk "core";
  home = mk "home";
}
