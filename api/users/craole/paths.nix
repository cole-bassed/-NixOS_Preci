{
  attrsets,
  options,
  types,
  top,
  ...
}: let
  inherit (attrsets) mapAttrs optionalAttrs;
  inherit (options) mkOption;
  inherit (types) attrs;
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
    options.${top}.paths = mkOption {
      type = attrs;
      default = {};
      description = "Derived user filesystem paths exposed as session variables and cd aliases.";
    };

    config.${top}.paths = {
      inherit downloads pictures projects;
      inherit (pictures) avatars wallpapers;
    };
  };
}
