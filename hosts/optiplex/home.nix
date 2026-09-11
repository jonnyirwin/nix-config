# Home Manager config specific to optiplex. Shared user config lives in
# modules/home; this file should stay small enough to read at a glance.
{ pkgs, ... }:
{
  jonny = {
    # desktop.enable, desktop.compositor and the whole of jonny.theme are
    # inherited from hosts/optiplex/default.nix via osConfig — declared once at
    # the system level because SDDM needs them before this profile exists.
    # Only the parts with no system-level counterpart are set here.
    desktop = {
      # Was config.d/display-settings.conf, rewritten at runtime by
      # resolution-switcher.sh. Landscape 1440p on the sole DisplayPort output.
      #
      # No transform: the panel used to be mounted portrait and everything
      # downstream had to be told about it — the greeter in default.nix, and
      # the console through it. Leaving the key out rather than writing
      # `transform = "normal"` is what lets those fall away too.
      outputs."DP-1".resolution = "2560x1440";

      # Trying the quickshell alternative (modules/home/desktop/quickshell)
      # in place of waybar + rofi's drun + mako. Flip back to "waybar" to
      # revert — nothing else here changes either way.
      shell = "quickshell";
    };

    backup = {
      # One collection point rather than a list of scattered sources: things
      # get copied into ~/backup by hand, and whatever is in there is what
      # goes off-machine. Deciding what deserves backing up is then a file
      # manager operation, not an edit to this file.
      #
      # The paths this replaced — Pictures, Takeout, Camera, photo-backup —
      # are already uploaded and STAY uploaded. `rclone copy` never deletes at
      # the destination, so dropping a path here only stops it being revisited;
      # onedrive:backup/optiplex/{Pictures,Camera,...} are untouched.
      #
      # Note ~/backup lives on the OS disk, which the reinstall wipes. That is
      # the point — it is a staging area for the upload, not a backup itself.
      # No extraExclude: with a single hand-curated path there is nothing to
      # carve out. `git/**` and `*.json` existed to skip checkouts and Google
      # Takeout sidecars in the old scattered photo paths; neither applies to
      # ~/backup, and a pattern that outlives its reason is how an exclude
      # list quietly starts dropping things you meant to keep. The shared
      # defaults in modules/home/backup.nix still apply.
      paths = [
        "/home/jonny/backup"
      ];
    };

    vaultSync = {
      # The Obsidian vault. Enabled here rather than in modules/home because
      # the checkout only exists on this machine; the phone is the other end.
      enable = true;
      path = "/home/jonny/git/Second-Brain";
    };

    # Trying JetBrains Mono here before it becomes the shared default in
    # modules/home/theme/default.nix. Has its own package, so no substitute
    # fallback is needed.
    #
    # ui is deliberately not the same family as mono: a monospace font is
    # built to align characters in a grid, not to read as prose at a glance,
    # which is what bar/notification/launcher text actually is. Inter is
    # what most non-Apple "looks like San Francisco" UIs actually use — SF
    # Pro itself is Apple-proprietary and isn't in nixpkgs.
    theme.fonts = {
      mono = {
        family = "JetBrains Mono";
        package = pkgs.jetbrains-mono;
        size = 16;
      };
      ui = {
        family = "Inter";
        package = pkgs.inter;
        size = 14;
      };
      substitute = null;
    };
  };

  home.sessionVariables = {
    # Chromium/Electron apps use the Wayland backend rather than XWayland.
    NIXOS_OZONE_WL = "1";
  };
}
