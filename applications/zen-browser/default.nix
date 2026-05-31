{inputs, ...}: {
  imports = [
    inputs.zen-browser.homeModules.twilight
    ./bookmarks.nix
    ./containers.nix
    ./general.nix
    ./keyboard.nix
    ./pins.nix
    ./policies.nix
    ./program.nix
    ./search.nix
    ./settings.nix
    ./spaces.nix
    ./style.nix
  ];
}
