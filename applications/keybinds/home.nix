{
  config,
  lib,
  pkgs,
  top,
  ...
}: let
  inherit (lib) attrValues filterAttrs mkDefault mkEnableOption mkIf mkOption optionalAttrs;
  inherit (lib.types) bool nullOr str submodule;

  dom = "applications";
  mod = "keybinds";

  cfg = config.${top}.${dom}.${mod};

  mkActionOption = description: defaults:
    mkOption {
      type = submodule {
        options = {
          key = mkOption {
            type = nullOr str;
            default = defaults.key or null;
            description = "Key chord for the ${description} action. Null leaves it unbound.";
          };

          command = mkOption {
            type = nullOr str;
            default = defaults.command or null;
            description = "Shell command used when the ${description} action is command-backed.";
          };
        };
      };
      default = {};
      description = "Shared semantic keybind definition for ${description}.";
    };

  enabledActions = filterAttrs (_: action: action.key != null) cfg.actions;
  commandAction = action: action.command != null;
  spawnAction = command: {
    action.spawn = ["sh" "-lc" command];
  };

  hyprBind = action: dispatch: "${cfg.mod}, ${action.key}, ${dispatch}";

  hyprExecBind = action:
    hyprBind action "exec, ${action.command}";

  niriKey = action: "Mod+${action.key}";
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption "shared compositor keybind profile";

    mod = mkOption {
      type = str;
      default = "SUPER";
      description = ''
        Primary compositor modifier. Hyprland uses this value directly; Niri
        maps it to its compositor-agnostic Mod alias.
      '';
    };

    actions = {
      terminal = mkActionOption "terminal" {
        key = "Return";
        command = "foot";
      };

      launcher = mkActionOption "launcher" {
        key = "D";
        command = "fuzzel";
      };

      closeWindow = mkActionOption "close window" {
        key = "Q";
      };

      reloadConfig = mkActionOption "reload config" {
        key = "R";
      };

      lock = mkActionOption "lock" {
        key = "L";
        command = "loginctl lock-session";
      };

      screenshot = mkActionOption "screenshot" {
        key = "Print";
        command = ''grim -g "$(slurp)" - | wl-copy'';
      };
    };

    hyprland.enable = mkOption {
      type = bool;
      default = true;
      description = "Whether to translate shared semantic binds to Hyprland syntax.";
    };

    niri.enable = mkOption {
      type = bool;
      default = true;
      description = "Whether to translate shared semantic binds to Niri syntax.";
    };
  };

  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = mkIf cfg.hyprland.enable {
      settings = {
        "$mod" = mkDefault cfg.mod;
        bind = attrValues (filterAttrs (_: bind: bind != null) {
          terminal =
            if enabledActions ? terminal && commandAction enabledActions.terminal
            then hyprExecBind enabledActions.terminal
            else null;
          launcher =
            if enabledActions ? launcher && commandAction enabledActions.launcher
            then hyprExecBind enabledActions.launcher
            else null;
          closeWindow =
            if enabledActions ? closeWindow
            then hyprBind enabledActions.closeWindow "killactive"
            else null;
          reloadConfig =
            if enabledActions ? reloadConfig
            then hyprBind enabledActions.reloadConfig "exec, hyprctl reload"
            else null;
          lock =
            if enabledActions ? lock && commandAction enabledActions.lock
            then hyprExecBind enabledActions.lock
            else null;
          screenshot =
            if enabledActions ? screenshot && commandAction enabledActions.screenshot
            then hyprExecBind enabledActions.screenshot
            else null;
        });
      };
    };

    home.packages = [
      pkgs.fuzzel
      pkgs.grim
      pkgs.slurp
      pkgs.wl-clipboard
    ];

    programs.niri.settings.binds = mkIf cfg.niri.enable (
      optionalAttrs (enabledActions ? terminal && commandAction enabledActions.terminal) {
        ${niriKey enabledActions.terminal} = spawnAction enabledActions.terminal.command;
      }
      // optionalAttrs (enabledActions ? launcher && commandAction enabledActions.launcher) {
        ${niriKey enabledActions.launcher} = spawnAction enabledActions.launcher.command;
      }
      // optionalAttrs (enabledActions ? closeWindow) {
        ${niriKey enabledActions.closeWindow}.action.close-window = [];
      }
      // optionalAttrs (enabledActions ? lock && commandAction enabledActions.lock) {
        ${niriKey enabledActions.lock} = spawnAction enabledActions.lock.command;
      }
      // optionalAttrs (enabledActions ? screenshot) {
        ${niriKey enabledActions.screenshot}.action.screenshot-screen = [];
      }
      # Niri reloads config changes automatically and does not expose a stable
      # reload-config bind action in niri-flake's action list, so the shared
      # reloadConfig action is intentionally only translated for Hyprland.
    );
  };
}
