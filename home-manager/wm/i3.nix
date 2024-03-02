{
  config,
  lib,
  ...
}: {
  config =
    lib.mkIf (config.environment.desktop
    == "i3") {
      xsession.windowManager.i3 = {
        enable = true;
      };
    };
}
