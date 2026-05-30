{
  config,
  lib,
  ...
}: let
  inherit (lib.attrsets) listToAttrs;

  home = config.home.homeDirectory;

  github = [
    "craole"
    "craole-cc"
    "cole-bassed"
  ];

  mkGithubHost = key: {
    name = "github_${key}";
    value = {
      hostname = "github.com";
      user = "git";
      identityFile = "${home}/.ssh/github/${key}";
      identitiesOnly = "yes";
    };
  };
in {
  programs.ssh = {
    enable = true;

    matchBlocks = listToAttrs (map mkGithubHost github);
  };
}
