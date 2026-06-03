{flake ? {}, ...}: let
  src =
    (
      if flake != null
      then {inherit flake;}
      else {}
    )
    // {
      names = {
        src = "dots";
        top = "_";
        lib = "lix";
      };

      paths = {
        src = ./.;
        api = ./api;
        dbg = ./debug;
        documentation = ./documentation;
        configurations = ./configurations;
        templates = ./templates;
        devShells = ./packages;
        utilities = ./utilities;
        secrets = ./secrets;
        libraries = ./libraries;
      };

      defaults = {
        host = {
          name = "nixos";
          id = null;
          description = null;
          type = null;
          class = "nixos";
          system = "x86_64-linux";
          stateVersion = null; # ? Must be the same as when the OS was installed
          paths.src = "/etc/nixos";

          localization = {
            latitude = 18.015;
            longitude = -77.49;
            locator = "manual";
            city = "Mandeville/Jamaica";
            timezone = "America/Jamaica";
            locale = "en_US.UTF-8";
          };
        };

        excludes = [
          "archive"
          "backup"
          "review"
          "temp"
        ];

        tags = [
          "core"
          "home"
        ];
      };
    };
in
  src // {libraries = import src.paths.libraries {inherit src;};}
