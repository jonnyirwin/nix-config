{ lib, config, ... }:

let
  cfg = config.jonny.locale;
in
{
  options.jonny.locale = {
    timeZone = lib.mkOption {
      type = lib.types.str;
      default = "Europe/London";
      description = "System timezone. Also consumed by the waybar clock module.";
    };

    defaultLocale = lib.mkOption {
      type = lib.types.str;
      default = "en_GB.UTF-8";
    };

    keyMap = lib.mkOption {
      type = lib.types.str;
      default = "uk";
      description = "Console keymap. The Wayland layout is set separately in sway.";
    };
  };

  config = {
    time.timeZone = cfg.timeZone;
    i18n.defaultLocale = cfg.defaultLocale;
    console.keyMap = cfg.keyMap;
  };
}
