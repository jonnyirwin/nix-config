{ config, lib, pkgs, ... }:

let
  cfg = config.jonny.desktop;
  p = config.jonny.theme.palette;
  font = config.jonny.theme.font;
in
{
  config = lib.mkIf cfg.enable {
    programs.rofi = {
      enable = true;
      package = pkgs.rofi; # Wayland support is built in since rofi-wayland merged
      terminal = lib.getExe pkgs.kitty;

      modes = [ "run" "drun" "window" ];

      extraConfig = {
        show-icons = true;
        drun-display-format = "{icon} {name}";
        location = 0;
        disable-history = false;
        hide-scrollbar = true;
        display-drun = "   Apps ";
        display-run = "   Run ";
        display-window = "   Window";
        display-Network = " 󰤨  Network";
        sidebar-mode = false;
      };

      # Pill theme matching waybar and tmux: mantle canvas, surface0 capsules,
      # accent-on-crust selection. Written as Nix so the accent follows
      # jonny.theme.accent — the old .rasi had it hard-coded between
      # `# >>> catppuccin-accent` markers for set-accent to rewrite.
      theme =
        let
          inherit (config.lib.formats.rasi) mkLiteral;
        in
        {
          "*" = {
            font = "${font.family} ${toString font.size}";

            background-color = mkLiteral "transparent";
            text-color = mkLiteral p.text;

            border-color = mkLiteral p.surface1;
            separatorcolor = mkLiteral "transparent";

            normal-background = mkLiteral "transparent";
            normal-foreground = mkLiteral p.text;
            alternate-normal-background = mkLiteral "transparent";
            alternate-normal-foreground = mkLiteral p.text;
            selected-normal-background = mkLiteral p.accent;
            selected-normal-foreground = mkLiteral p.crust;

            active-background = mkLiteral "transparent";
            active-foreground = mkLiteral p.blue;
            alternate-active-background = mkLiteral "transparent";
            alternate-active-foreground = mkLiteral p.blue;
            selected-active-background = mkLiteral p.blue;
            selected-active-foreground = mkLiteral p.crust;

            urgent-background = mkLiteral "transparent";
            urgent-foreground = mkLiteral p.red;
            alternate-urgent-background = mkLiteral "transparent";
            alternate-urgent-foreground = mkLiteral p.red;
            selected-urgent-background = mkLiteral p.red;
            selected-urgent-foreground = mkLiteral p.crust;
          };

          window = {
            transparency = "real";
            location = mkLiteral "center";
            anchor = mkLiteral "center";
            width = mkLiteral "640px";
            border = mkLiteral "1px solid";
            border-radius = mkLiteral "18px";
            border-color = mkLiteral p.surface1;
            padding = mkLiteral "14px";
            background-color = mkLiteral p.mantle;
            cursor = "default";
          };

          mainbox = {
            enabled = true;
            spacing = mkLiteral "10px";
            padding = mkLiteral "0";
            background-color = mkLiteral "transparent";
            children = map mkLiteral [ "inputbar" "message" "listview" ];
          };

          inputbar = {
            enabled = true;
            spacing = mkLiteral "10px";
            padding = mkLiteral "0 16px";
            min-height = mkLiteral "40px";
            background-color = mkLiteral p.surface0;
            border-radius = mkLiteral "999px";
            text-color = mkLiteral p.text;
            children = map mkLiteral [ "prompt" "entry" "num-filtered-rows" "textbox-num-sep" "num-rows" ];
          };

          prompt = {
            padding = mkLiteral "0 2px 0 0";
            background-color = mkLiteral "transparent";
            text-color = mkLiteral p.accent;
            vertical-align = mkLiteral "0.5";
          };

          entry = {
            padding = mkLiteral "0";
            background-color = mkLiteral "transparent";
            text-color = mkLiteral p.text;
            cursor = mkLiteral "text";
            placeholder = "search…";
            placeholder-color = mkLiteral p.overlay1;
            vertical-align = mkLiteral "0.5";
          };

          num-filtered-rows = {
            expand = false;
            background-color = mkLiteral "transparent";
            text-color = mkLiteral p.overlay1;
            vertical-align = mkLiteral "0.5";
          };

          num-rows = {
            expand = false;
            background-color = mkLiteral "transparent";
            text-color = mkLiteral p.overlay1;
            vertical-align = mkLiteral "0.5";
          };

          textbox-num-sep = {
            expand = false;
            str = "/";
            background-color = mkLiteral "transparent";
            text-color = mkLiteral p.overlay0;
            vertical-align = mkLiteral "0.5";
          };

          case-indicator = {
            spacing = mkLiteral "0";
            background-color = mkLiteral "transparent";
            text-color = mkLiteral p.overlay1;
            vertical-align = mkLiteral "0.5";
          };

          listview = {
            enabled = true;
            columns = 1;
            lines = 8;
            cycle = true;
            dynamic = true;
            scrollbar = false;
            fixed-height = false;
            fixed-columns = true;
            spacing = mkLiteral "2px";
            padding = mkLiteral "6px 2px 0 2px";
            background-color = mkLiteral "transparent";
            cursor = "default";
          };

          element = {
            enabled = true;
            spacing = mkLiteral "10px";
            padding = mkLiteral "0 14px";
            min-height = mkLiteral "34px";
            border-radius = mkLiteral "999px";
            background-color = mkLiteral "transparent";
            text-color = mkLiteral p.text;
            cursor = mkLiteral "pointer";
          };

          "element normal.normal" = { background-color = mkLiteral "transparent"; text-color = mkLiteral p.text; };
          "element alternate.normal" = { background-color = mkLiteral "transparent"; text-color = mkLiteral p.text; };
          "element selected.normal" = { background-color = mkLiteral p.accent; text-color = mkLiteral p.crust; };
          "element normal.active" = { background-color = mkLiteral "transparent"; text-color = mkLiteral p.blue; };
          "element alternate.active" = { background-color = mkLiteral "transparent"; text-color = mkLiteral p.blue; };
          "element selected.active" = { background-color = mkLiteral p.blue; text-color = mkLiteral p.crust; };
          "element normal.urgent" = { background-color = mkLiteral "transparent"; text-color = mkLiteral p.red; };
          "element alternate.urgent" = { background-color = mkLiteral "transparent"; text-color = mkLiteral p.red; };
          "element selected.urgent" = { background-color = mkLiteral p.red; text-color = mkLiteral p.crust; };

          element-icon = {
            size = mkLiteral "22px";
            padding = mkLiteral "0 6px 0 0";
            background-color = mkLiteral "transparent";
            text-color = mkLiteral "inherit";
            cursor = mkLiteral "inherit";
            vertical-align = mkLiteral "0.5";
          };

          element-text = {
            background-color = mkLiteral "transparent";
            text-color = mkLiteral "inherit";
            cursor = mkLiteral "inherit";
            highlight = mkLiteral "bold ${p.peach}";
            vertical-align = mkLiteral "0.5";
          };

          message = {
            padding = mkLiteral "0";
            margin = mkLiteral "0";
            background-color = mkLiteral "transparent";
            border = mkLiteral "0";
          };

          textbox = {
            padding = mkLiteral "6px 14px";
            border-radius = mkLiteral "999px";
            background-color = mkLiteral p.surface0;
            text-color = mkLiteral p.text;
          };

          error-message = {
            padding = mkLiteral "8px 14px";
            border-radius = mkLiteral "999px";
            background-color = mkLiteral p.red;
            text-color = mkLiteral p.crust;
          };
        };
    };
  };
}
