{
  user,
  top,
  ...
}: let
  profiles = {
    craole = "32288735+Craole@users.noreply.github.com";
    craole-cc = "134658831+craole-cc@users.noreply.github.com";
    cole-bassed = "75517056+cole-bassed@users.noreply.github.com";
  };
in {
  core = {
    ${top}.applications.git = {
      enable = true;
      inherit profiles;
      defaultProfile = profiles.craole;
    };
  };
  home = {
    ${top}.applications = {
      zen-browser.enable = true;
      git.extraRepositories = {"${user.home}/.dots/" = "cole-bassed";};
    };
    home.sessionVariables = {
      EDITOR = "hx";
      VISUAL = "code";
    };
  };
}
