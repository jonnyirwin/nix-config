{
  config,
  pkgs,
  pkgs-unstable,
  ...
}: {
  imports = [
    ./wm/sway.nix
    ./wm/swaylock.nix
    ./wm/rofi.nix
    ./wm/waybar.nix
    ./wm/mako.nix
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

  nixpkgs.overlays = [
    (_: prev: {
      aseprite = prev.aseprite.overrideAttrs (_: _: rec {
        version = "1.3.1";
        src = prev.fetchFromGitHub {
          owner = "aseprite";
          repo = "aseprite";
          rev = "v${version}";
          fetchSubmodules = true;
          hash = "sha256-8eQI3eZm5YTjhwdiElERuyM/X59TbFowHP4S6X0B+d8=";
        };
      });
    })
  ];

  home.stateVersion = "23.05"; # Please read the comment before changing.

  home.packages = [
    (pkgs.nerdfonts.override {fonts = ["NerdFontsSymbolsOnly"];})
    pkgs-unstable.obsidian
    pkgs.keepassxc
    pkgs.intel-one-mono
    pkgs.waybar
    pkgs.inter
    pkgs.godot_4
    pkgs.starship
    pkgs.aseprite
    pkgs.python3
    pkgs.qutebrowser
    pkgs.microsoft-edge
    pkgs.nodejs
		pkgs.spotify
		pkgs.cabal-install
		pkgs.ghc
		pkgs.meld
  ];
  fonts.fontconfig.enable = true;

	services.syncthing.enable = true;

  programs = {
    fish.enable = true;
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
    starship.enable = true;
    ripgrep.enable = true;
    fzf = {
      enable = true;
      enableFishIntegration = true;
    };
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    pinentryFlavor = "tty";
  };

  programs.vscode.enable = true;
  programs.tmux = {
    enable = true;
    shortcut = "a";
  };

  home.file."./wallpaper.jpg".source = ./wallpaper.jpg;

  services.network-manager-applet.enable = true;
}
