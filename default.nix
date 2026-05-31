{lib ? (import <nixpkgs/lib>), ...}: let
  inherit (lib.lists) head;
in {
  modules = [
    ./ai
    ./applications
    ./interface
    ./modules
    ./profiles
    ./secrets
  ];
  user = {
    name = "craole";
    description = "Craig 'Craole' Cole";
  };
  # api = {
  #   hosts.Preci = {dots = "/home/craole/.dots";};
  #   # users =
  # };
  top = "dots";
  dots = "/etc/nixos";
  ignore = [
    "archive"
    "backup"
    "review"
    "temp"
  ];
  entrypoints.nix = let
    ext = "nix";
    candidates = map (name: "${name}.${ext}") [
      "default"
      "shell"
      "flake"
      "configuration"
      "_"
    ];
  in {
    inherit candidates;
    main = head candidates;
  };
  tags = ["core" "home"];
}
