{
  osConfig,
  top,
  ...
}: {
  ${top} = {
    interface = {
      browsers = {
        enable = true;
      };
      keybinds = {
        enable = true;
      };
    };

    applications = {
      zen-browser = {
        enable = true;
      };
      git = {
        enable = true;
      };
      noctalia = {
        enable = true;
      };
      starship = {
        enable = true;
      };
      vicinae = {
        enable = true;
      };
    };
  };

  home = {
    inherit (osConfig.system) stateVersion;

    sessionVariables = {
      EDITOR = "hx";
      VISUAL = "code";
    };
  };

  imports = [
    ./git.nix
  ];
}
