{ config, lib, ... }:

let
  cfg = config.jonny.desktop;
  font = config.jonny.theme.font;
in
{
  config = lib.mkIf cfg.enable {
    fonts.fontconfig.enable = true;

    # Dank Mono is proprietary and installed by hand:
    #   mkdir -p ~/.local/share/fonts && cp DankMono*.otf ~/.local/share/fonts/
    # This alias means every config can name it unconditionally: fontconfig
    # returns Dank Mono when present and falls through to Intel One Mono when
    # not, so a fresh machine still renders correctly.
    #
    # Numbered 09- so the target="scan" rule is registered before fontconfig
    # scans the font directories.
    xdg.configFile."fontconfig/conf.d/09-dank-mono.conf".text = ''
      <?xml version="1.0"?>
      <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
      <fontconfig>
        <!-- Dank Mono Italic ships without a spacing property, which makes
             kitty reject it as non-monospace. Force it. -->
        <match target="scan">
          <test name="family"><string>${font.family}</string></test>
          <test name="style"><string>Italic</string></test>
          <edit name="spacing"><int>100</int></edit>
        </match>

        <!-- binding="same" appends rather than replaces, so Dank Mono still
             wins outright when it is installed. -->
        <alias binding="same">
          <family>${font.family}</family>
          <prefer><family>Intel One Mono</family></prefer>
        </alias>
      </fontconfig>
    '';
  };
}
