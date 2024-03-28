{
  config,
  lib,
  ...
}: let
  colorHelpers = import ../../helpers/colors.nix {inherit lib;};
in {
  programs.waybar = {
    enable = true;
    settings = {
      bar = {
        spacing = 15;
        layer = "top";
        position = "top";
        modules-left = ["sway/workspaces" "sway/mode"];
        modules-center = ["clock" "idle_inhibitor"];
        modules-right = ["pulseaudio" "bluetooth" "battery" "tray"];
        "sway/window" = {
          max-length = 50;
        };
        battery = {
          bat = "BAT1";
          interval = 60;
          states = {
            warning = 30;
            critical = 15;
          };
          format-icons = [" " " " " " " " " "];
          format = "{icon} {capacity}%";
        };
        clock = {
          format = "󰥔 {:%a, %d. %b  %H:%M}";
        };
        bluetooth = {
          format = "󰂯 {status}";
          format-connected = " {num_connections} connected";
          tooltip-format = "{controller_alias}\t{controller_address}";
          tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
        };
        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "󰀠";
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
            default = ["" ""];
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
      					background: ${colorHelpers.hexToRGBA config.colorScheme.palette.base07 0.1};
            }

            .modules-left, .modules-center, .modules-right {
               color: #${config.colorScheme.palette.base05};
               	background-color: #${config.colorScheme.palette.base01};
               	border-radius: 1000px;
      					padding: 0;
      					margin: 2px 5px;
               }

      			.modules-right {
      				padding: 0 15px;
      			}

      			#clock {
      				padding: 2px 10px;
      				background-color: #${config.colorScheme.palette.base00};
      				color: #${config.colorScheme.palette.base07};
      				border-radius: 1000px;
      			}

      			#idle_inhibitor {
      				padding: 2px 15px 2px 0;
      				color: #${config.colorScheme.palette.base09};
      			}

      			#idle_inhibitor.activated {
      				color: #${config.colorScheme.palette.base0B};
      			}

      			 #workspaces {
      				border-radius: 1000px;
      				background-color: #${config.colorScheme.palette.base00};
      			}

      			#workspaces button {
      				border-radius: 1000px;
      				background-color: #${config.colorScheme.palette.base00};
      				color: #${config.colorScheme.palette.base04};
      				padding: 2px 6px;
      			}

      #workspaces button:hover {
      		background: #${config.colorScheme.palette.base01};
      		color: #${config.colorScheme.palette.base05};
      		padding: 2px 6px;
      		box-shadow: inherit;
      		text-shadow: inherit;
      }

      			#workspaces button.focused {
      				color: #${config.colorScheme.palette.base0A};
      				background-color: #${config.colorScheme.palette.base01};
      			}

      			#pulseaudio {
      				color: #${config.colorScheme.palette.base0A};
      			}

      			#bluetooth {
      				color: #${config.colorScheme.palette.base0B};
      			}

      			#battery {
      				color: #${config.colorScheme.palette.base0D};
      			}

      			#tray {
      				color: #${config.colorScheme.palette.base0E};
      			}

      			#mode {
      				color: #${config.colorScheme.palette.base08};
      				background-color: #${config.colorScheme.palette.base00};
      				border-radius: 1000px;
      				padding: 2px 10px;
      				margin: 0;
      				border: 1px solid #${config.colorScheme.palette.base08};
      			}
    '';
  };
}
