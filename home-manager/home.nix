{
  config,
  pkgs,
  lib,
  pkgs-unstable,
  nix-colors,
  ...
}: {
  imports = [
    ./desktop.nix
    ./kitty.nix
    ./gtk.nix
    ./nvim
  ];

  home = {
    username = "jonny";
    homeDirectory = "/home/jonny";
    sessionVariables = {
      GPG_TTY = "$(tty)";
      GTK_THEME = "Catppuccin-Mocha-Blue-Compact-Dark";
      WLR_NO_HARDWARE_CURSORS = 1;
    };
  };
  nixpkgs.config.allowUnfree = true;

  home.stateVersion = "23.05"; # Please read the comment before changing.

  home.packages = [
    (pkgs.nerdfonts.override {fonts = ["NerdFontsSymbolsOnly"];})
    pkgs-unstable.obsidian
    pkgs.keepassxc
    pkgs.cowsay
    pkgs.intel-one-mono
    pkgs.waybar
    pkgs.inter
    pkgs.lolcat
    pkgs-unstable.godot_4
    pkgs-unstable.aseprite
    pkgs.python3
    pkgs.qutebrowser
    pkgs.microsoft-edge
    pkgs.nodejs
    pkgs.spotify
    pkgs.cabal-install
    pkgs.ghc
    pkgs.meld
    pkgs.neofetch
    pkgs-unstable.discord
    pkgs.libnotify
    pkgs.glib
    pkgs.unzip
    pkgs.elixir
  ];
  fonts.fontconfig.enable = true;

  colorScheme = nix-colors.colorSchemes.catppuccin-frappe;

  services = {
    syncthing.enable = true;

    gpg-agent = {
      enable = true;
      enableSshSupport = true;
      pinentryFlavor = "tty";
    };

    network-manager-applet.enable = true;
  };

  programs = {
    fish = {
      enable = true;
      interactiveShellInit = ''
        set fish_greeting
      '';
    };
    git = {
      enable = true;
      userEmail = "git@jbi.im";
      userName = "Jonny Irwin";
      signing = {
        key = "A3DDFE095FBAB7FE";
        signByDefault = true;
      };
      extraConfig = {
        pull = {
          rebase = false;
        };
        init = {
          defaultBranch = "main";
        };
      };
    };
    gpg.enable = true;
    home-manager.enable = true;
    starship = let
      inherit (config.colorScheme.palette) base00 base01 base02 base03 base04 base05 base06 base07 base08 base09 base0A base0B base0C base0D base0E base0F;
    in {
      enable = true;
      enableFishIntegration = true;
      enableTransience = true;
      settings = {
        add_newline = true;
        #palette = "base16";

        format = lib.concatStrings [
          "[](fg:#${base01})"
					"[λ ](fg:#${base0B} bg:#${base01})"
          "$username"
          "[ ](fg:#${base01} bg:#${base03})"
					"$directory"
          "[](fg:#${base03} bg:#${base0B})"
					"[ ](bg:#${base0B})"
          "[](fg:#${base0B} bg:#${base0D})"
					"[ ](bg:#${base0D})"
          "[](fg:#${base0D} bg:#${base01})"
					"[ ](bg:#${base01})"
          "[](fg:#${base01})"
          "$line_break"
          "$character"
        ];

        username = {
          style_user = "fg:#${base07} bg:#${base01}";
          style_root = "";
          show_always = true;
          format = "[$user ]($style)";
        };

				directory = {
					style = "fg:#${base0B} bg:#${base03}";
					format = "[$path ]($style)";
				};

        #palettes.base16 = {
        #base00 = "#${config.colorScheme.palette.base00}";
        #base01 = "#${config.colorScheme.palette.base01}";
        #base02 = "#${config.colorScheme.palette.base02}";
        #base03 = "#${config.colorScheme.palette.base03}";
        #base04 = "#${config.colorScheme.palette.base04}";
        #base05 = "#${config.colorScheme.palette.base05}";
        #base06 = "#${config.colorScheme.palette.base06}";
        #base07 = "#${config.colorScheme.palette.base07}";
        #base08 = "#${config.colorScheme.palette.base08}";
        #base09 = "#${config.colorScheme.palette.base09}";
        #base0A = "#${config.colorScheme.palette.base0A}";
        #base0B = "#${config.colorScheme.palette.base0B}";
        #base0C = "#${config.colorScheme.palette.base0C}";
        #base0D = "#${config.colorScheme.palette.base0D}";
        #base0E = "#${config.colorScheme.palette.base0E}";
        #base0F = "#${config.colorScheme.palette.base0F}";
        #};
      };
    };
    ripgrep.enable = true;
    fzf = {
      enable = true;
      enableFishIntegration = true;
    };
  };

  programs.vscode.enable = true;
  programs.tmux = {
    enable = true;
    shortcut = "a";
  };

  environment.desktop = "sway";
}
