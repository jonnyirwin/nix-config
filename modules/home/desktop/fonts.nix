{ config, lib, ... }:

let
  cfg = config.jonny.desktop;
  fonts = config.jonny.theme.fonts;
  sub = fonts.substitute;
in
{
  config = lib.mkIf cfg.enable {
    fonts.fontconfig.enable = true;

    # Substitute alias, derived from jonny.theme.fonts rather than naming
    # families here. Dank Mono is proprietary and installed by hand:
    #   mkdir -p ~/.local/share/fonts && cp DankMono*.otf ~/.local/share/fonts/
    # The alias means every config can name it unconditionally — fontconfig
    # returns it when present and falls through to the substitute when not, so
    # a fresh machine still renders correctly.
    #
    # Numbered 09- so the target="scan" rule is registered before fontconfig
    # scans the font directories.
    xdg.configFile."fontconfig/conf.d/09-font-substitute.conf" = lib.mkIf (sub != null) {
      text = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
        <fontconfig>
          <!-- Dank Mono Italic ships without a spacing property, which makes
               kitty reject it as non-monospace. Force it. -->
          <match target="scan">
            <test name="family"><string>${fonts.mono.family}</string></test>
            <test name="style"><string>Italic</string></test>
            <edit name="spacing"><int>100</int></edit>
          </match>

          <!-- <accept> APPENDS the substitute after the real family, so the
               real family is matched first and wins whenever it is installed;
               the substitute is only reached when it is absent. <prefer> would
               prepend it and shadow the real font even when present. -->
          <alias binding="same">
            <family>${fonts.mono.family}</family>
            <accept><family>${sub.family}</family></accept>
          </alias>
        </fontconfig>
      '';
    };
  };
}
