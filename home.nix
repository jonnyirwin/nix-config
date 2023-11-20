{ config, pkgs, self, ... }:

{

# Home Manager needs a bit of information about you and the paths it should
# manage.
	home.username = "jonny";
	home.homeDirectory = "/home/jonny";
	home.sessionVariables = {
		GPG_TTY = "$(tty)";
	};

	nixpkgs.config.allowUnfree = true;

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
		pkgs.ponysay
		(pkgs.nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
		pkgs.obsidian
		pkgs.keepassxc
# # Adds the 'hello' command to your environment. It prints a friendly
# # "Hello, world!" when run.
# pkgs.hello

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

	programs.nixvim = import ./home-manager/nvim.nix;
	programs.vscode.enable = true;

}
