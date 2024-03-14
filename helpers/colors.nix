{ lib }:

let
  hexToRGB = hexStr:
    assert lib.strings.isString hexStr; # Ensure hexStr is a string
    let
      cleanHex = lib.strings.removePrefix "#" hexStr;
      r = lib.strings.substring 0 2 cleanHex;
      g = lib.strings.substring 2 2 cleanHex;
      b = lib.strings.substring 4 2 cleanHex;
			hexPairsToDec = pair: builtins.fromJSON ("\"0x" + pair + "\"");
    in
    {
      red = hexPairsToDec r;
      green = hexPairsToDec g;
      blue = hexPairsToDec b;
    };

  hexToRGBA = hexStr: opacity:
    assert lib.strings.isString hexStr; # Ensure hexStr is a string
    assert builtins.isFloat opacity && opacity >= 0.0 && opacity <= 1.0; # Ensure opacity is a float between 0 and 1.0
    let
      rgb = hexToRGB hexStr;
      alpha = opacity;
    in
    "rgba(${toString rgb.red},${toString rgb.green},${toString rgb.blue},${toString alpha})";
in
{
  inherit hexToRGB;
  inherit hexToRGBA;
}
