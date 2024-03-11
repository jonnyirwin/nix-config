{
  config,
  pkgs,
  ...
}: {
  programs.rofi = let
    inherit (config.lib.formats.rasi) mkLiteral;
  in {
    enable = true;
    cycle = false;
    location = "center";
    package = pkgs.rofi-wayland;
    inherit (config.wayland.windowManager.sway.config) terminal;
    font = "Inter 14";
    theme = {
      "*" = {
        background-color = mkLiteral "#${config.colorScheme.palette.base00}";
      };

      window = {
        width = mkLiteral "600px";
        height = mkLiteral "410px";
        padding = mkLiteral "10px";
        border-radius = mkLiteral "10px";
        border-color = mkLiteral "#${config.colorScheme.palette.base01}";
        #border = 1;
      };

      inputbar = {
        children = ["entry"];
      };

      entry = {
        placeholder = "Search...";
        text-color = mkLiteral "#${config.colorScheme.palette.base03}";
        background-color = mkLiteral "#${config.colorScheme.palette.base00}";
        padding = mkLiteral "5px";
        border-radius = mkLiteral "10px";
      };

      listview = {
        padding = mkLiteral "5px";
      };

      element = {
        orientation = "vertical";
        spacing = mkLiteral "15px";
        padding = mkLiteral "15px";
        children = ["element-icon" "element-text"];
      };

      element-text = {
        text-color = mkLiteral "#${config.colorScheme.palette.base05}";
        background-color = mkLiteral "inherit";
        vertical-align = mkLiteral "0.5";
      };

      "element.selected" = {
        text-color = mkLiteral "#${config.colorScheme.palette.base04}";
        background-color = mkLiteral "#${config.colorScheme.palette.base01}";
        border-radius = mkLiteral "10px";
      };

      element-icon = {
        size = mkLiteral "1.5em";
        background-color = mkLiteral "inherit";
      };
    };
    extraConfig = {
      modi = "drun";
      show-icons = true;
      fixed-num-lines = true;
		  monitor = mkLiteral "-1";
    };
  };
}
