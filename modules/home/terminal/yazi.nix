{ config, lib, ... }:

# yazi itself is a TUI and works fine without a display, so it is not gated.
# Its openers are not: zathura, imv and mpv all need a compositor. On a
# headless host those entries are dropped rather than left pointing at
# programs that are not installed, and the affected mime types fall through to
# the `open` rule.
let
  cfg = config.jonny.desktop;

  guiOpeners = {
    pdf = [{ run = ''zathura "$@"''; orphan = true; desc = "Open in Zathura"; }];
    image = [{ run = ''imv-wayland "$@"''; orphan = true; desc = "Open in imv"; }];
    video = [{ run = ''mpv "$@"''; orphan = true; desc = "Play in mpv"; }];
    audio = [{ run = ''mpv "$@"''; orphan = true; desc = "Play in mpv"; }];
  };

  guiRules = [
    { mime = "application/pdf"; use = [ "pdf" "open" ]; }
    { mime = "image/*"; use = [ "image" "open" ]; }
    { mime = "video/*"; use = [ "video" "open" ]; }
    { mime = "audio/*"; use = [ "audio" "open" ]; }
  ];
in
{
  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    shellWrapperName = "yy"; # keep the pre-26.05 name; `y` is the new default

    settings = {
      mgr = {
        ratio = [ 1 3 4 ]; # parent : current : preview
        sort_by = "natural"; # file2 sorts before file10
        sort_dir_first = true;
        show_hidden = false; # toggle live with .
        show_symlink = true;
      };

      preview = {
        tab_size = 2;
        max_width = 1000;
        max_height = 1000;
        wrap = "yes";
        image_filter = "lanczos3";
        image_quality = 80;
      };

      tasks = {
        micro_workers = 10;
        macro_workers = 4;
      };

      log.enabled = false;

      opener = {
        edit = [{ run = ''nvim "$@"''; block = true; desc = "Edit in nvim"; }];
        open = [{ run = ''xdg-open "$@"''; orphan = true; desc = "Open with xdg-open"; }];
      } // lib.optionalAttrs cfg.enable guiOpeners;

      # First match wins, so the catch-all stays last.
      open.rules = [
        { mime = "text/*"; use = [ "edit" "open" ]; }
        { mime = "application/json"; use = [ "edit" "open" ]; }
        { mime = "application/xml"; use = [ "edit" "open" ]; }
      ] ++ lib.optionals cfg.enable guiRules ++ [
        { mime = "*"; use = "open"; }
      ];
    };

    keymap.mgr.prepend_keymap = [
      {
        on = [ "g" "D" ];
        run = "cd /run/media/jonny";
        desc = "Go to mounted drives";
      }
    ];
  };

  # Replaces the hand-maintained theme.toml (771 lines) and the bundled
  # Catppuccin-mocha.tmTheme (2111 lines) — both were a manual copy of what this
  # module generates, and they follow jonny.theme.flavor now.
  catppuccin.yazi.enable = true;
}
