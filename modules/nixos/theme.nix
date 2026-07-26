{ lib, ... }:

# The host's colour scheme, declared at the system level.
#
# This is the single place a host states its theme. Two consumers read it:
#
#   * SDDM (modules/nixos/desktop/sddm.nix), which runs before any Home Manager
#     profile is activated and so cannot read the Home Manager option.
#   * The Home Manager side (modules/home/theme/default.nix), whose own
#     jonny.theme options default to these values via osConfig.
#
# So a host sets scheme/accent once, here, and the greeter and the session
# agree by construction rather than by remembering to edit both. A host that
# genuinely wants them to differ can still override the Home Manager option.
#
# Lives outside desktop/ deliberately: these are plain data with no dependency
# on a graphical session, so a headless host can carry a theme for its console
# without pulling in the desktop module tree.
let
  myLib = import ../../lib { inherit lib; };
in
{
  options.jonny.theme = {
    scheme = lib.mkOption {
      type = lib.types.enum myLib.schemeNames;
      default = "catppuccin-mocha";
      description = ''
        Colour scheme for the host. Schemes live in lib/schemes/; see
        jonny.theme.scheme on the Home Manager side for what it drives.
      '';
    };

    accent = lib.mkOption {
      type = lib.types.enum myLib.accentNames;
      default = "purple";
      description = ''
        The focus colour, named by hue rather than by a scheme's brand name for
        a colour — so "purple" means the same thing in every scheme and survives
        switching. See jonny.theme.accent on the Home Manager side.
      '';
    };
  };
}
