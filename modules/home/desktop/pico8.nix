{ config, lib, pkgs, ... }:

# PICO-8 — fantasy console for making/sharing tiny games.
#
# Unlike aseprite.nix, this is not "unfree but Nix can still build it from
# public source" — PICO-8 is paid software with no stable download URL (you
# get the zip after logging into your lexaloffle.com account), so Nix cannot
# fetch it at all. `requireFile` is nixpkgs' standard answer to that: only a
# sha256 of the zip is committed here (a hash of copyrighted bytes isn't
# itself copyrighted, so that's safe in a public repo), and the build fails
# with instructions until the file you already own is registered locally:
#
#   nix-store --add-fixed sha256 ~/pico-8/pico-8_0.2.7a6_amd64.zip
#
# After that one-time step, the derivation is fully reproducible: same hash
# in, same store path out, on any machine that has done the same step.
let
  cfg = config.jonny.desktop;
  version = "0.2.7a6";

  src = pkgs.requireFile {
    name = "pico-8_${version}_amd64.zip";
    sha256 = "edf2ce854740585b0f98884ee09d63f9ab8e6c8772e0148a902927b6408c9eaa";
    url = "https://www.lexaloffle.com/pico-8.php";
    message = ''
      PICO-8 is paid software with no public download URL. Buy/download it at
      https://www.lexaloffle.com/pico-8.php (Raspberry Pi/Linux amd64 build),
      then register the zip you already own with Nix:

        nix-store --add-fixed sha256 /path/to/pico-8_${version}_amd64.zip
    '';
  };

  pico8 = pkgs.stdenv.mkDerivation {
    pname = "pico-8";
    inherit version;
    inherit src;

    nativeBuildInputs = [ pkgs.unzip pkgs.autoPatchelfHook ];
    # pico8_dyn links libSDL2 at runtime; pico8 (static SDL2) doesn't need it,
    # but autoPatchelf only wires up what's actually referenced.
    buildInputs = [ pkgs.SDL2 ];
    # pico8's bundled SDL2 opens its video, input and audio backends via
    # dlopen-by-soname rather than a normal ELF NEEDED entry, so autoPatchelf
    # never sees these as dependencies to wire up on its own — without
    # runtimeDependencies forcing them onto RPATH, video failed outright
    # ("No available video device" / "Could not initialize UDEV"), and audio
    # failed silently (no error, just no sound).
    runtimeDependencies = with pkgs; [
      libGL
      libx11
      libxcursor
      libxext
      libxi
      libxrandr
      libxxf86vm
      udev
      alsa-lib
      libpulseaudio
    ];

    unpackPhase = ''
      unzip -q "$src" -d .
    '';

    installPhase = ''
      mkdir -p $out/bin $out/share/pico-8 $out/share/applications
      install -Dm444 pico-8/lexaloffle-pico8.png $out/share/icons/hicolor/128x128/apps/pico8.png

      cp -r pico-8/. $out/share/pico-8/
      chmod +x $out/share/pico-8/pico8 $out/share/pico-8/pico8_dyn
      ln -s $out/share/pico-8/pico8 $out/bin/pico8
      ln -s $out/share/pico-8/pico8_dyn $out/bin/pico8_dyn

      install -Dm444 /dev/stdin $out/share/applications/pico8.desktop <<EOF
      [Desktop Entry]
      Type=Application
      Name=PICO-8
      Comment=Fantasy console for making, sharing and playing tiny games
      Exec=$out/bin/pico8 %f
      Icon=pico8
      Categories=Game;Development;
      Terminal=false
      EOF
    '';

    meta = {
      description = "Fantasy console for making, sharing, and playing tiny games";
      homepage = "https://www.lexaloffle.com/pico-8.php";
      license = lib.licenses.unfree;
      platforms = [ "x86_64-linux" ];
      mainProgram = "pico8";
    };
  };
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pico8 ];
  };
}
