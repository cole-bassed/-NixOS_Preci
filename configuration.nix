{
  config,
  pkgs,
  ...
}: {
  imports = [./core];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      timeout = 1;
    };
  };

  nixpkgs = {
    config.allowUnfree = true;
  };

  nix = {
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  networking = {
    hostName = "Preci";
    networkmanager.enable = true;
  };

  time.timeZone = "America/Jamaica";
  i18n.defaultLocale = "en_US.UTF-8";

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  environment = {
    sessionVariables = {
      EDITOR = "hx";
      VISUAL = "code";
    };
    systemPackages = with pkgs; [
      helix
      nixd
      nil
      alejandra
      ripgrep-all
      ripgrep
      fd
      sd
      coreutils-full
      pciutils
      wl-clipboard
      # vscode-fhs
      btop
    ];
  };

  programs = {
    bash = {
      enable = true;
      blesh.enable = true;
    };
  };

  services = {
    openssh.enable = true;
    kmscon.enable = true;
    getty = {
      autologinOnce = true;
      autologinUser = "craole";
    };
  };

  system.stateVersion = "25.11";

  users.users.craole = {
    isNormalUser = true;
    description = "Craig Craole Cole";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };
}
