{
  config,
  inputs,
  lib,
  pkgs,
  top,
  ...
}: let
  dom = "applications";
  mod = "noctalia";
  cfg = config.${top}.${dom}.${mod};

  inherit (lib.modules) mkDefault mkForce mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) package str;
in {
  imports = [inputs.noctalia.homeModules.default];

  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption "Noctalia common panel/bar layer";

    package = mkOption {
      type = package;
      default = pkgs.noctalia-shell;
      description = "Noctalia shell package used for the common Wayland panel/bar layer.";
    };

    command = mkOption {
      type = str;
      default = "noctalia-shell";
      description = "Command used by compositor-specific startup hooks.";
    };

    onHyprland =
      mkEnableOption "Whether to start Noctalia from Hyprland exec-once."
      // {default = true;};

    onNiri =
      mkEnableOption "Whether to start Noctalia from Niri spawn-at-startup."
      // {default = true;};
  };

  config = mkIf cfg.enable {
    programs = {
      noctalia-shell = {
        enable = mkDefault true;
        package = mkForce cfg.package;
        # The upstream module warns that systemd integration is deprecated, so
        # keep startup explicit in each compositor for now.
        systemd.enable = mkDefault false;
      };

      niri = {
        settings.spawn-at-startup = mkIf cfg.onNiri [{argv = [cfg.command];}];
      };
    };

    wayland.windowManager.hyprland = {
      settings.exec-once = mkIf cfg.onHyprland [cfg.command];
    };
  };
}
