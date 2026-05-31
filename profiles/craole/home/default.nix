{
  osConfig,
  top,
  ...
}: {
  ${top} = {
    interface = {
      browser.enable = true;
      keybind.enable = true;
    };

    applications = {
      zen-browse.enable = true;
      git.enable = true;
      noctalia.enable = true;
      starship.enable = true;
      vicinae.enable = true;
    };
  };

  home = {
    #: TODO This has to be defined for every user, so we need to put it somewhere else
    inherit (osConfig.system) stateVersion;

    sessionVariables = {
      EDITOR = "hx";
      VISUAL = "code";
    };
  };

  imports = [./git.nix];
}
