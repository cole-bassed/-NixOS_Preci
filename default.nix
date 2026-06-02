{
  inputs ? {},
  modules ? {},
  packages ? {},
  libraries ? {nixpkgs = import <nixpkgs/lib>;},
  ...
}: let
  info = rec {
    name = "dots";
    home = "/etc/nixos";
    names = {
      flake = name;
      lib = "lix";
      top = "_";
    };
  };

  paths = {
    src = ./.;
    ai = ./ai;
    api = ./api;
    apps = ./applications;
    docs = ./documentation;
    env = ./secrets;
    interface = ./interface;
    lib = ./libraries;
    base = ./base;
  };

  defaults = {
    host = {
      name = null;
      id = null;
      description = null;
      type = null;
      class = "nixos";
      system = "x86_64-linux";
      stateVersion = null; #? Must be the same as when the OS was installed
      paths.flake = info.home;

      localization = {
        latitude = 18.015;
        longitude = -77.49;
        locator = "manual";
        city = "Mandeville/Jamaica";
        timezone = "America/Jamaica";
        language = "en_US.UTF-8";
      };
    };
    excludes = [
      "archive"
      "backup"
      "review"
      "temp"
    ];
    tags = ["core" "home"];
  };
in {
  inherit inputs packages modules defaults;
  libraries = import ./libraries {
    inherit
      defaults
      info
      inputs
      libraries
      modules
      packages
      paths
      ;
  };
}
