{
  config,
  pkgs,
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

  #nixpkgs.overlays = [
    #(_: prev: {
      #aseprite = prev.aseprite.overrideAttrs (_: _: rec {
        #version = "1.3.5";
        #src = prev.fetchFromGitHub {
          #owner = "aseprite";
          #repo = "aseprite";
          #rev = "v${version}";
          #fetchSubmodules = true;
          #hash = "sha256-QXhoSfVyMLLTKFUDeX7WaNcX2IvDK729LxV0u0q1AoA=";
        #};
      #});
    #})
  #];

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
    pkgs.starship
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

  programs.vscode.enable = true;
  programs.tmux = {
    enable = true;
    shortcut = "a";
  };

  home.file."./wallpaper.jpg".source = ./wallpaper.jpg;
	environment.desktop = "sway";
}
