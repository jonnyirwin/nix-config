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
        pdf = [{ run = ''zathura "$@"''; orphan = true; desc = "Open in Zathura"; }];
        image = [{ run = ''imv-wayland "$@"''; orphan = true; desc = "Open in imv"; }];
        video = [{ run = ''mpv "$@"''; orphan = true; desc = "Play in mpv"; }];
        audio = [{ run = ''mpv "$@"''; orphan = true; desc = "Play in mpv"; }];
        open = [{ run = ''xdg-open "$@"''; orphan = true; desc = "Open with xdg-open"; }];
      };

      open.rules = [
        { mime = "text/*"; use = [ "edit" "open" ]; }
        { mime = "application/json"; use = [ "edit" "open" ]; }
        { mime = "application/xml"; use = [ "edit" "open" ]; }
        { mime = "application/pdf"; use = [ "pdf" "open" ]; }
        { mime = "image/*"; use = [ "image" "open" ]; }
        { mime = "video/*"; use = [ "video" "open" ]; }
        { mime = "audio/*"; use = [ "audio" "open" ]; }
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
