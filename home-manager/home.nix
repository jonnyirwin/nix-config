{ config, pkgs, self, pkgs-unstable, ... }:

{

  imports = [
		./wm/sway.nix
		./wm/rofi.nix
	];

# Home Manager needs a bit of information about you and the paths it should
# manage.
	home.username = "jonny";
	home.homeDirectory = "/home/jonny";
	home.sessionVariables = {
		GPG_TTY = "$(tty)";
	};

	nixpkgs.config.allowUnfree = true;

	nixpkgs.overlays = [
		(final: prev: {
			aseprite = prev.aseprite.overrideAttrs (finalAttrs: previousAttrs: rec {
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
		pkgs-unstable.neovim
		pkgs.python3


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

	#programs.nixvim = import ./nvim/nvim.nix;
	programs.vscode.enable = true;
	#programs.waybar.enable = true;

home.file.".config/kitty/kitty.conf".text = ''
font_family								Intel One Mono 
italic_font							  Intel One Mono Italic	
font_size									16.0
background_opacity				0.9
hide_window_decorations		yes

# vim:ft=kitty

## name: Tokyo Night
## license: MIT
## author: Folke Lemaitre
## upstream: https://github.com/folke/tokyonight.nvim/raw/main/extras/kitty_tokyonight_night.conf


background #1a1b26
foreground #c0caf5
selection_background #33467c
selection_foreground #c0caf5
url_color #73daca
cursor #c0caf5
cursor_text_color #1a1b26

# Tabs
active_tab_background #7aa2f7
active_tab_foreground #16161e
inactive_tab_background #292e42
inactive_tab_foreground #545c7e
#tab_bar_background #15161e

# normal
color0 #15161e
color1 #f7768e
color2 #9ece6a
color3 #e0af68
color4 #7aa2f7
color5 #bb9af7
color6 #7dcfff
color7 #a9b1d6

# bright
color8 #414868
color9 #f7768e
color10 #9ece6a
color11 #e0af68
color12 #7aa2f7
color13 #bb9af7
color14 #7dcfff
color15 #c0caf5

# extended colors
color16 #ff9e64
color17 #db4b4b
'';

home.file.".config/waybar/config".text = ''
{
    "layer": "top",
    "position": "top",
    "modules-left": ["sway/workspaces", "sway/mode"],
    "modules-center": ["clock", "idle_inhibitor"],
    "modules-right": ["pulseaudio", "bluetooth", "battery", "tray"],
    "sway/window": {
        "max-length": 50
    },
    "battery": {
    	"bat": "BAT1",
        "format": "󰁹 {capacity}%",
    },
    "clock": {
        "format": "󰥔 {:%a, %d. %b  %H:%M}"
    },
    "bluetooth": {
	"format": "󰂯 {status}", 
	"format-connected": " {num_connections} connected",
	"tooltip-format": "{controller_alias}\t{controller_address}",
	"tooltip-format-connected": "{controller_alias}\t{controller_address}\n\n{device_enumerate}",
	"tooltip-format-enumerate-connected": "{device_alias}\t{device_address}",
    },
    "idle_inhibitor": {
        "format":  "{icon}", 
	"format-icons": {
	    "activated": "󰀠",
	    "deactivated": "󰒲"
	}
    },
    "pulseaudio": {
        "format": "{icon} {volume}%",
    "format-bluetooth": "{icon} {volume}%",
    "format-muted": "",
    "format-icons": {
        "headphone": "",
        "hands-free": "",
        "headset": "󰋎",
        "phone": "",
        "portable": "",
        "car": "",
        "default": ["", ""]
    },
    "scroll-step": 1,
    "on-click": "pavucontrol"
    }
}
'';

home.file.".config/waybar/style.css".text = ''
* {
    font-family: Inter, "Symbols Nerd Font Mono", sans-serif;
    font-size: 14px;
}

window#waybar {
    background-color: rgba(17,24,39,0.7);
    color: #ffffff;
    transition-property: background-color;
    transition-duration: .5s;
}

window#waybar.hidden {
    opacity: 0.2;
}

#workspaces button {
    margin: 5px 0 5px 3px;	
    padding: 0 5px;
    background-color: #242c3a;
    color: #9ca3af;
    border-radius: 100%;
}

#workspaces button:hover {
    background: rgba(0, 0, 0, 0.2);
}

#workspaces button.focused {
    background-color: #374151;
    color: #ffffff;
}

#workspaces button.urgent {
    background-color: #eb4d4b;
}

#clock,
#battery,
#bluetooth,
#cpu,
#memory,
#disk,
#temperature,
#backlight,
#network,
#pulseaudio,
#custom-media,
#tray,
#mode,
#idle_inhibitor,
#mpd {
    padding: 0 10px;
    color: #ffffff;
    margin: 6px 2px;
    background-color: #242c3a;
    border-radius: 8px;
}

#mode {
    background-color: #f97316;
    color: #111827;
}


#window,
#workspaces {
    margin: 0 4px;
}

/* If workspaces is the leftmost module, omit left margin */
.modules-left > widget:first-child > #workspaces {
    margin-left: 0;
}

/* If workspaces is the rightmost module, omit right margin */
.modules-right > widget:last-child > #workspaces {
    margin-right: 0;
}

#battery.charging, #battery.plugged {
    color: #ffffff;
    background-color: #26A65B;
}

@keyframes blink {
    to {
        background-color: #ffffff;
        color: #000000;
    }
}

#battery.critical:not(.charging) {
    background-color: #f53c3c;
    color: #ffffff;
    animation-name: blink;
    animation-duration: 0.5s;
    animation-timing-function: linear;
    animation-iteration-count: infinite;
    animation-direction: alternate;
}

label:focus {
    background-color: #000000;
}
'';

home.file."./wallpaper.jpg".source = ./wallpaper.jpg;

services.network-manager-applet.enable = true;

gtk.iconTheme = {
	package = pkgs.gnome.adwaita-icon-theme;
	name = "adwaita-icon-theme";
};

}
