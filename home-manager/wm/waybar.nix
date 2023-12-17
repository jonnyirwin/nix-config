{ pkgs, lib, config, ... }:
{
	programs.waybar = {
		enable = true;
		settings = {
			bar = {
			layer = "top";
			position = "top";
			modules-left = [ "sway/workspaces" "sway/mode" ];
			modules-center = [ "clock" "idle_inhibitor" ];
			modules-right = [ "pulseaudio" "bluetooth" "battery" "tray"];
			"sway/window" = {
				max-length = 50;
			};
			battery = {
				bat = "BAT1";
				format = "󰁹 {capacity}%";
			};
			clock = {
				format = "󰥔 {:%a, %d. %b  %H:%M}";
			};
			bluetooth = {
				format= "󰂯 {status}"; 
				format-connected = " {num_connections} connected";
				tooltip-format = "{controller_alias}\t{controller_address}";
				tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{device_enumerate}";
				tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
    			};
			idle_inhibitor = {
        			format = "{icon}"; 
				format-icons = {
	    				activated =  "󰀠";
	    				deactivated = "󰒲";
				};		
    			};
			pulseaudio = {
        			format = "{icon} {volume}%";
    				format-bluetooth = "{icon} {volume}%";
    				format-muted = "";
    				format-icons = {
        				headphone = "";
        				hands-free = "";
        				headset = "󰋎";
        				phone = "";
        				portable = "";
        				car = "";
        				default = [ "" "" ];
    				};
    				scroll-step = 1;
    				on-click = "pavucontrol";
    			};
			};
		};
		style = ''
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
	};
}
