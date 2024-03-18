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

  colorScheme = nix-colors.colorSchemes.catppuccin-mocha;

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
			disabled = false;
			format = "[ $symbol($version)]($style)";
			style = "fg:#${base00} bg:#${base0D}";
    in {
      enable = true;
      enableFishIntegration = true;
      enableTransience = true;
      settings = {
        add_newline = true;
        #palette = "base16";

        format = lib.concatStrings [
          "[](fg:#${base02})"
					"[λ ](fg:#${base0B} bg:#${base02})"
          "$username"
          "[ ](fg:#${base02} bg:#${base09})"
					"$directory"
          "[](fg:#${base09} bg:#${base0B})"
					"[$git_branch$git_status](bg:#${base0B})"
          "[](fg:#${base0B} bg:#${base0D})"
					"$dotnet"
					"$elixir"
					"$elm"
					"$haskell"
					"$lua"
					"$nix_shell"
					"$nodejs"
					"$ocaml"
					"$python"
					"$rust"
					"$scala"
					"$shell"
					"$vagrant"
          "[](fg:#${base0D} bg:#${base0E})"
					"$time"
          "[](fg:#${base0E})"
          "$line_break"
          "$character"
        ];

        username = {
          style_user = "fg:#${base07} bg:#${base02}";
          style_root = "";
          show_always = true;
          format = "[$user ]($style)";
        };

				directory = {
					style = "fg:#${base00} bg:#${base09}";
					format = "[$path ]($style)";
				};

				time = {
					disabled = false;
					format = "[   $time]($style)";
					style = "fg:#${base00} bg:#${base0E}";
				};

				git_branch = {
					format = "([ $symbol$branch]($style))";
					style = "fg:#${base00} bg:#${base0B}";
					symbol = " ";
				};

				git_status = {
					disabled = false;
					style = "bold	fg:#${base00} bg:#${base0B}";
					format = "([ ❲$all_status$ahead_behind❳]($style))";	
				};

				nodejs = {
					inherit disabled format style;
					symbol = " ";
				};

				haskell = {
					inherit disabled format style;
					symbol = " ";
				};

				ocaml = {	
					inherit disabled format style;
					symbol = " ";
				};

				elm = {
					inherit disabled format style;
					symbol = " ";
				};

				lua = {
					inherit disabled format style;
					symbol = " ";
				};

				python = {
					inherit disabled format style;
					symbol = " ";
				};

				rust = {
					inherit disabled format style;
					symbol = " ";
				};

				elixir = {
					inherit disabled format style;
					symbol = " ";
				};

				vagrant = {
					inherit disabled format style;
					symbol = " ";
				};

				dotnet = {
					inherit disabled format style;
					symbol = " ";
				};

				scala = {
					inherit disabled format style;
					symbol = " ";
				};

				nix_shell = {
					inherit disabled format style;
					symbol = " ";
				};

				character = {
					success_symbol = "[ ↳ ](fg:#${base0B})";
					error_symbol = "[ ↳ ](fg:#${base08})";
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
		baseIndex = 1;
		customPaneNavigationAndResize = true;
		mouse = true;
		topIndex = 1;
		escapeTime = 100;
		extraConfig = ''
			set-option -g status-position top
		'';
  };

  environment.desktop = "sway";
}
