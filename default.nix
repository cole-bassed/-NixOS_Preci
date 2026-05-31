{}: {
  system = "x86_64-linux";
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
  api = {hosts.Preci = {dots = "/home/craole/.dots";};};
  top = "dots";
  dots = "/etc/nixos";
  ignore = [
    "archive"
    "backup"
    "review"
    "temp"
  ];
  entrypoint = "default.nix";
  tags = ["core" "home"];
}
