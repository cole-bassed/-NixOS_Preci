{osConfig, ...}: {
  home = {
    inherit (osConfig.system) stateVersion;

    sessionVariables = {
      EDITOR = "hx";
      VISUAL = "code";
    };
  };

  imports = [
    ./git.nix
    ./starship.nix
  ];
}
