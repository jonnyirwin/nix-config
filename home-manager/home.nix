{ config, pkgs, pkgs-unstable, ... }:

{
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

# Home Manager needs a bit of information about you and the paths it should
# manage.
	home.username = "jonny";
	home.homeDirectory = "/home/jonny";
	home.sessionVariables = {
		GPG_TTY = "$(tty)";
		GTK_THEME = "Catppuccin-Mocha-Blue-Compact-Dark";
		WLR_NO_HARDWARE_CURSORS=1;
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

# This value determines the Home Manager release that your configuration is
# compatible with. This helps avoid breakage when a new Home Manager release
# introduces backwards incompatible changes.
#
# You should not change this value, even if you update Home Manager. If you do
# want to update the value, then make sure to first check the Home Manager
# release notes.
	home.stateVersion = "23.05"; # Please read the comment before changing.

# The home.packages option allows you to install Nix packages into your
# environment.
		home.packages = [
		(pkgs.nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
			pkgs-unstable.obsidian
			pkgs.keepassxc
			pkgs.intel-one-mono
			pkgs.waybar
			pkgs.inter
			pkgs.godot_4
			pkgs.starship
			pkgs.aseprite# # Adds the 'hello' command to your environment. It prints a friendly
# # "Hello, world!" when run.
# pkgs.hello
			pkgs.syncthing
			pkgs.python3
			pkgs.qutebrowser
			pkgs.microsoft-edge


# # It is sometimes useful to fine-tune packages, for example, by applying
# # overrides. You can do that directly here, just don't forget the
# # parentheses. Maybe you want to install Nerd Fonts with a limited number of
# # fonts?
# (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

# # You can also create simple shell scripts directly inside your
# # configuration. For example, this adds a command 'my-hello' to your
# # environment:
#r(pkgs.writeShellScriptBin "my-hello" ''
#   echo "Hello, ${config.home.username}!"
# '')
			];
	fonts.fontconfig.enable = true;

# Home Manager is pretty good at managing dotfiles. The primary way to manage
# plain files is through 'home.file'.
	home.file = {
# # Building this configuration will create a copy of 'dotfiles/screenrc' in
# # the Nix store. Activating the configuration will then make '~/.screenrc' a
# # symlink to the Nix store copy.
# ".screenrc".source = dotfiles/screenrc;

# # You can also set the file content immediately.
# ".gradle/gradle.properties".text = ''
#r  org.gradle.console=verbose
#   org.gradle.daemon.idletimeout=3600000
# '';
	};

# You can also manage environment variables but you will have to manually
#rsource
#
#  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
#
# or
#
#  /etc/profiles/per-user/jonny/etc/profile.d/hm-session-vars.sh
#
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
