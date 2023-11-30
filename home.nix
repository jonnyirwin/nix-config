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
		pkgs.ponysay
		(pkgs.nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
		pkgs.obsidian
		pkgs.keepassxc
		pkgs.intel-one-mono
		pkgs.font-awesome_4 
		pkgs.waybar
		pkgs.inter
		pkgs.gnome.gnome-font-viewer
		pkgs.godot_4
		pkgs.starship
		pkgs.aseprite# # Adds the 'hello' command to your environment. It prints a friendly
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
	#programs.waybar.enable = true;
	programs.wofi.enable = true;
	wayland.windowManager.sway = {
    enable = true;
		config = {
		  output = {
				"*" = {
					bg = "~/wallpaper.jpg fill";
				};
			};
			terminal = "kitty";
			bars = [
        {command = "${config.programs.waybar.package}/bin/waybar";}
			];
		};
		#config = {
      #modifier = "Mod4";
		#};
		extraConfig = ''
   # Default config for sway
#
# Copy this to ~/.config/sway/config and edit it to your liking.
#
# Read `man 5 sway` for a complete reference.

### Variables
#
# Logo key. Use Mod1 for Alt.
set $mod Mod4
# Home row direction keys, like vim
set $left h
set $down j
set $up k
set $right l
# Your preferred terminal emulator
set $term kitty
# Your preferred application launcher
# Note: pass the final command to swaymsg so that the resulting window can be opened
# on the original workspace that the command was run on.
# set $menu dmenu_path | dmenu | xargs swaymsg exec --
set $menu wofi | xargs swaymsg exec --


### Output configuration
#
# Default wallpaper (more resolutions are available in /usr/share/backgrounds/sway/)
#output * bg ~/Pictures/wallpaper.png fill
#
# Example configuration:
#
#   output HDMI-A-1 resolution 1920x1080 position 1920,0
#
# You can get the names of your outputs by running: swaymsg -t get_outputs

### Idle configuration
#
# Example configuration:`
#

exec swayidle -w \
                timeout 300 'swaylock -f -c 000000' \
                timeout 600 'swaymsg "output * dpms off"' \
                     resume 'swaymsg "output * dpms on"' \
                before-sleep 'swaylock -f -c 000000'	 

bindSym $mod+l exec swaylock -f -c 000000	 
#
# This will lock your screen after 300 seconds of inactivity, then turn off
# your displays after another 300 seconds, and turn your screens back on when
# resumed. It will also lock your screen before your computer goes to sleep.

### Input configuration
#
# Example configuration:
#
#   input "2:14:SynPS/2_Synaptics_TouchPad" {
#       dwt enabled
#       tap enabled
#       natural_scroll enabled
#       middle_emulation enabled
#   }
#
# You can get the names of your inputs by running: swaymsg -t get_inputs
# Read `man 5 sway-input` for more information about this section.

input * {
    xkb_layout "gb"
}

### Key bindings
#
# Basics:
#
    # Start a terminal
    bindsym $mod+Return exec $term

    # Kill focused window
    bindsym $mod+Shift+q kill

    # Start your launcher
    bindsym $mod+d exec $menu

    # Drag floating windows by holding down $mod and left mouse button.
    # Resize them with right mouse button + $mod.
    # Despite the name, also works for non-floating windows.
    # Change normal to inverse to use left mouse button for resizing and right
    # mouse button for dragging.
    floating_modifier $mod normal

    # Reload the configuration file
    bindsym $mod+Shift+c reload

    # Exit sway (logs you out of your Wayland session)
    bindsym $mod+Shift+e exec swaynag -t warning -m 'What do you want to do?' -B 'Power off' 'systemctl poweroff' -B 'Reboot' 'systemctl reboot' -B 'Logout' 'swaymsg exit'
#
# Moving around:
#
    # Move your focus around
    #bindsym $mod+$left focus left
    #bindsym $mod+$down focus down
    #bindsym $mod+$up focus up
    #bindsym $mod+$right focus right
    # Or use $mod+[up|down|left|right]
    #bindsym $mod+Left focus left
    #bindsym $mod+Down focus down
    #bindsym $mod+Up focus up
    #bindsym $mod+Right focus right

    # Move the focused window with the same, but add Shift
    bindsym $mod+Shift+$left move left
    bindsym $mod+Shift+$down move down
    bindsym $mod+Shift+$up move up
    bindsym $mod+Shift+$right move right
    # Ditto, with arrow keys
    bindsym $mod+Shift+Left move left
    bindsym $mod+Shift+Down move down
    bindsym $mod+Shift+Up move up
    bindsym $mod+Shift+Right move right

		bindsym $mod+Control+Shift+Right move workspace to output right
    bindsym $mod+Control+Shift+Left move workspace to output left
    bindsym $mod+Control+Shift+Down move workspace to output down
    bindsym $mod+Control+Shift+Up move workspace to output up
#
# Workspaces:
#
    # Switch to workspace
    bindsym $mod+1 workspace number 1
    bindsym $mod+2 workspace number 2
    bindsym $mod+3 workspace number 3
    bindsym $mod+4 workspace number 4
    bindsym $mod+5 workspace number 5
    bindsym $mod+6 workspace number 6
    bindsym $mod+7 workspace number 7
    bindsym $mod+8 workspace number 8
    bindsym $mod+9 workspace number 9
    bindsym $mod+0 workspace number 10
    # Move focused container to workspace
    bindsym $mod+Shift+1 move container to workspace number 1
    bindsym $mod+Shift+2 move container to workspace number 2
    bindsym $mod+Shift+3 move container to workspace number 3
    bindsym $mod+Shift+4 move container to workspace number 4
    bindsym $mod+Shift+5 move container to workspace number 5
    bindsym $mod+Shift+6 move container to workspace number 6
    bindsym $mod+Shift+7 move container to workspace number 7
    bindsym $mod+Shift+8 move container to workspace number 8
    bindsym $mod+Shift+9 move container to workspace number 9
    bindsym $mod+Shift+0 move container to workspace number 10
    # Note: workspaces can have any name you want, not just numbers.
    # We just use 1-10 as the default.
#
# Layout stuff:
#
    # You can "split" the current object of your focus with
    # $mod+b or $mod+v, for horizontal and vertical splits
    # respectively.
    bindsym $mod+h splith
    bindsym $mod+v splitv

    # Switch the current container between different layout styles
    bindsym $mod+s layout stacking
    bindsym $mod+w layout tabbed
    bindsym $mod+e layout toggle split

    # Make the current focus fullscreen
    bindsym $mod+f fullscreen

    # Toggle the current focus between tiling and floating mode
    bindsym $mod+Shift+space floating toggle

    # Swap focus between the tiling area and the floating area
    bindsym $mod+space focus mode_toggle

    # Move focus to the parent container
    bindsym $mod+a focus parent
#
# Scratchpad:
#
    # Sway has a "scratchpad", which is a bag of holding for windows.
    # You can send windows there and get them back later.

    # Move the currently focused window to the scratchpad
    bindsym $mod+Shift+minus move scratchpad

    # Show the next scratchpad window or hide the focused scratchpad window.
    # If there are multiple scratchpad windows, this command cycles through them.
    bindsym $mod+minus scratchpad show
#
# Resizing containers:
#
    mode "resize" {
# left will shrink the containers width
# right will grow the containers width
# up will shrink the containers height
# down will grow the containers height
	    #bindsym $left resize shrink width 10px
		    #bindsym $down resize grow height 10px
		    #bindsym $up resize shrink height 10px
		    #bindsym $right resize grow width 10px

# Ditto, with arrow keys
		    #bindsym Left resize shrink width 10px
		    #bindsym Down resize grow height 10px
		    #bindsym Up resize shrink height 10px
		    #bindsym Right resize grow width 10px

# Return to default mode
		    #bindsym Return mode "default"
		    #bindsym Escape mode "default"
    }
bindsym $mod+r mode "resize"

#
# Status Bar:
#
# Read `man 5 sway-bar` for more information about this section.
#bar {
	#position top

# When the status_command prints a new line to stdout, swaybar updates.
    # The default just shows the current date and time.
    # status_command while date +'%Y-%m-%d %I:%M:%S %p'; do sleep 1; done
    
    #swaybar_command waybar

    #colors {
        #statusline #ffffff
        #background #323232
        #inactive_workspace #32323200 #32323200 #5c5c5c
    #}
#}

title_align center
default_border none

###
### Screen brightness
###

bindsym XF86MonBrightnessUp exec light -A 5
bindsym XF86MonBrightnessDown exec light -U 5

#gaps inner 5

bindsym $mod+Shift+d exec "echo 'swaymsg output eDP-1 scale 1.5\nswaymsg output eDP-1 scale 1\nswaymsg output eDP-1 disable\nswaymsg output eDP-1 enable\nswaymsg output HDMI-A-2 mode 2560x1440\nswaymsg output HDMI-A-2 mode 1920x1080\nswaymsg output HDMI-A-2 mode 3840x2160' | wofi -d | xargs -I {} kitty sh -c {}"
	'';
	};

home.file.".config/wofi/config".text = ''
width=400
height=200
location=center
show=drun
prompt=Search...
filter_rate=100
allow_markup=true
no_actions=true
halign=fill
orientation=vertical
content_halign=fill
insensitive=true
allow_images=true
image_size=24
gtk_dark=true
'';

home.file.".config/wofi/styles.css".text = ''
  @define-color clear rgba(0, 0, 0, 0.0);

window {
    margin: 2px;
    border: 0px solid;
    background-color: #111827;
    border-radius: 8px;
}

#input {
    padding: 4px;
    margin: 4px;
    border: none;
    color: #ffffff; 
    background-color: @clear;
    outline: none;
}

#inner-box {
    margin: 4px;
    border: 0px solid;
    background-color: @clear;
    border-radius: 8px;
}

#outer-box {
    margin: 2px;
    border: none;
    border-radius: 8px;
    background-color: @clear;
}

#scroll {
    margin: 0px;
    border: none;
}

#text {
    color: #9CA3AF;
    margin-left: 8px;
}

#text:selected {
    color: #ffffff;
    margin: 0px 8px;
    border: none;
    border-radius: 8px;
}

#entry {
    margin: 0px 0px;
    border: none;
    border-radius: 0px;
    background-color: transparent;
}

#entry:selected {
    margin: 0px 0px;
    border: none;
    border-radius: 8px;
    background-color: #242c3a;
}
'';

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

home.file."./wallpaper.jpg".source = ./home-manager/wallpaper.jpg;

}
