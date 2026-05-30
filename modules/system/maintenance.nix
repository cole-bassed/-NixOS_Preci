{
  config,
  pkgs,
  dots,
  ...
}: {
  nix = {
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  environment = {
    sessionVariables = {
      DOTS = dots;
      EDITOR = "hx";
      VISUAL = "code";
    };
    shellAliases = {
      ede-dots = "$EDITOR ${dots}";
      ide-dots = "$VISUAL ${dots}";

      up = "cd ${dots} && sudo nix flake update";
      hix = "sudo hx ${dots}";
      fix = "sudo alejandra ${dots}";
      llx = "ll ${dots}";
      ltx = "lt ${dots}";
      ltr = "lr ${dots}";
      switch = "nh os switch ${dots}";
    };
    systemPackages = with pkgs; [
      #~@ Nix - formatters, LSPs, cache, prefetchers
      alejandra # ? Opinionated Nix formatter (primary)
      nixfmt # ? RFC-style Nix formatter (secondary)
      cachix # ? Binary cache management CLI
      nil # ? Nix LSP for static analysis
      nixd # ? Nix language server daemon
      nix-index # ? Index nixpkgs files for nix-locate
      nix-info # ? System info helper for bug reports
      nix-output-monitor # ? Pretty build progress - pipe via nom
      nix-prefetch # ? Prefetch arbitrary sources
      nix-prefetch-docker # ? Prefetch Docker image hashes
      nix-prefetch-github # ? Prefetch GitHub repo hashes
      nix-prefetch-scripts # ? Common prefetch script helpers
      nvfetcher # ? Auto-update/pin flake sources

      #~@ System - core utilities, hardware inspection
      coreutils # ? GNU core utilities
      uutils-coreutils-noprefix # ? Rust reimplementation of coreutils
      findutils # ? GNU find, xargs, locate
      gawk # ? GNU awk for text processing
      getent # ? Query Name Service Switch databases
      gnused # ? GNU stream editor
      lshw # ? Detailed hardware lister
      pciutils # ? PCI tools - lspci
      usbutils # ? USB tools - lsusb
      gnome-randr # ? Display configuration for GNOME/Wayland
      wlr-randr # ? Display configuration for wlroots WMs
      # wl-clipboardi #? Command-line copy/paste utilities for Wayland
      wl-clipboard-rs # ? Command-line copy/paste utilities for Wayland, written in Rust
      procs # ? Modern ps replacement with tree view

      #~@ Files - navigation, search, sync, cleanup
      dua # ? Interactive disk usage analyzer (TUI)
      dust # ? Intuitive du replacement
      eza # ? Modern ls with git integration
      fd # ? Fast, user-friendly find alternative
      fzf # ? General-purpose fuzzy finder
      lsd # ? Stylish ls with icons and Git integration
      ouch # ? 7zip wrapper for [de]compressing archives with progress
      p7zip # ? 7zip CLI for archive management
      rsync # ? Fast incremental file sync/transfer
      sad # ? CLI find-and-replace (batch sed)
      sd # ? CLI find and replace (sed alternative)
      trashy # ? Safe trash-aware rm alternative

      #~@ Network - transfer, GitHub
      curl # ? Command-line HTTP client
      wget # ? Non-interactive network downloader
      gh # ? Official GitHub CLI
      gitui # ? Fast terminal UI for Git

      #~@ Dev - editors, VCS, data, media
      # bat # ? Cat clone with syntax highlighting and paging
      helix # ? Modal editor with native LSP + tree-sitter
      imagemagick # ? Image conversion and manipulation
      jql # ? JSON Query Language CLI tool built with Rust
      jq # ? Lightweight and flexible command-line JSON processor
      qimgv # ? Fast image viewer with minimal UI
      ripgrep # ? Fast recursive grep (rg)
      viu # ? Fast terminal image viewer with truecolor support

      #~@ Shell - monitoring, productivity, aesthetics
      btop # ? Rich resource monitor (htop replacement)
      fastfetch # ? Fast system info fetcher
      fend # ? Arbitrary-precision calculator REPL
      figlet # ? ASCII art text banners
    ];
  };

  programs = {
    bash = {
      enable = true;
      blesh.enable = true;
      undistractMe = {
        enable = true;
        timeout = 60;
        playSound = false;
      };
      vteIntegration = true;
    };
    bcc = {
      enable = true;
    };
    direnv = {
      enable = true;
      silent = true;
      settings = {
        global = {
          log_format = "-";
          log_filter = "^$";
        };
      };
    };
    git = {
      enable = true;
      lfs.enable = true;
      prompt.enable = true;
      config = {
        init = {defaultBranch = "main";};
        url = {"https://github.com/" = {insteadOf = ["gh:" "github:"];};};
      };
    };
    bat = {
      enable = true;
      extraPackages = with pkgs.bat-extras; [
        batdiff
        batman
        prettybat
      ];
      settings = {
        italic-text = "always";
        pager = "less --RAW-CONTROL-CHARS --quit-if-one-screen --mouse";
        # paging = "never";
        # theme = "TwoDark";
      };
    };
    fzf = {
      fuzzyCompletion = true;
      keybindings = true;
    };
    starship = {
      enable = true;
    };
    nh = {
      enable = true;
      flake = dots;
      clean = {
        enable = true;
        dates = "weekly";
        extraArgs = "--keep 5 --keep-since 3d";
      };
    };
    television = {
      enable = true;
      enableBashIntegration = config.programs.bash.enable;
      enableFishIntegration = config.programs.fish.enable;
      enableZshIntegration = config.programs.zsh.enable;
    };
    tmux = {
      enable = true;
    };
  };

  services = {
  };
}
