{
  top,
  lib,
  ...
}: let
  inherit (lib.attrsets) mapAttrs optionalAttrs;
in {
  core = {};
  home = {config, ...}: let
    home = config.home.homeDirectory;
    gitProfiles = config.${top}.applications.git.profiles or {};

    pictures = let
      base = home + "/Pictures";
    in {
      inherit base;
      avatars = {
        inherit base;
        session = base + "/Avatars/avatar.jpg";
        whatsapp = base + "/Avatars/avatar.jpg";
      };
      wallpapers = {
        inherit base;
        light = base + "/Wallpapers/light";
        dark = base + "/Wallpapers/dark";
      };
    };

    downloads = {base = home + "/Downloads";};

    projects = let
      base = home + "/Projects";
    in {
      inherit base;
      repos =
        optionalAttrs (gitProfiles != {})
        (mapAttrs (name: _: base + "/${name}") gitProfiles);
    };
  in {
    ${top}.paths = {
      inherit downloads pictures projects;
      inherit (pictures) avatars wallpapers;
    };
  };
}
