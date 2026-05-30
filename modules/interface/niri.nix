{
  inputs,
  pkgs,
  ...
}: let
  inherit (inputs.niri) nixosModules overlays;
in {
  imports = [nixosModules.niri];
  nixpkgs.overlays = [overlays.niri];

  programs = {
    niri = {
      enable = true;
      package = pkgs.niri-unstable;
    };
    uwsm = {
      enable = true;
      waylandCompositors.niri = {
        prettyName = "Niri";
        comment = "Niri compositor managed by UWSM";
        binPath = "/run/current-system/sw/bin/niri-session";
      };
    };
  };

  environment = {
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };
    systemPackages = with pkgs; [
      wl-clipboard-rs
      wayland-utils
      libsecret
      cage
      gamescope
      xwayland-satellite-unstable
    ];
  };
}
