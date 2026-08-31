{ config, lib, pkgs, ... }:

let
  cfg = config.jonny.desktop;
in
{
  config = lib.mkIf cfg.enable {
    # Only what you invoke *directly*. Anything a script in scripts.nix needs is
    # pinned there via runtimeInputs, so listing it again here would be a second
    # place to keep in step — grim, slurp, tesseract, imagemagick, wtype,
    # flameshot, wf-recorder, autotiling, udiskie and swaybg are all deliberately
    # absent for that reason.
    home.packages = with pkgs; [
      # ---- Wayland session ----
      wdisplays # GUI output configurator, bound to Mod+Shift+D

      # ---- Clipboard ----
      wl-clipboard # also used interactively, not just by scripts
      wl-clip-persist # keeps the clipboard alive after the source app exits;
      # launched from sway's startup list, not a package you invoke
      cliphist # clipboard history

      # ---- Audio ----
      pulsemixer
      pavucontrol
      playerctl
      # pactl, for anything that speaks the PulseAudio protocol to PipeWire's shim
      pulseaudio

      # ---- Misc desktop tools ----
      brightnessctl
      libnotify # notify-send, used interactively too
      ffmpeg

      # ---- File management ----
      # Graphical browsing to go with yazi's terminal one (Mod+Y). Picks up
      # the Catppuccin GTK theme from gtk.nix automatically. Its device
      # sidebar is a GVfs client, not an automounter in its own right — that
      # is udisks2/gvfs (system side, modules/nixos/desktop/storage.nix) plus
      # udiskie (desktop/storage.nix), so a card or drive shows up there the
      # moment it is inserted rather than needing to be mounted by hand.
      thunar
      # Thumbnails in Thunar's icon view — the main payoff being actual
      # previews of photos straight off an SD card instead of generic icons.
      tumbler

      # ---- Design / engineering ----
      kicad # PCB design
      # `openscad-unstable` carries the Manifold geometry backend, which is far
      # faster on CSG-heavy models than the 2021.01 release this attr pins. It
      # is off for now: the nightly fails to link under LTO — lld rejects a
      # malformed .debug_gdb_scripts section — and there is no cache hit, so it
      # builds from source and fails. Switch back once that clears upstream.
      openscad # programmatic CAD
      inkscape # vector graphics

      # ---- Embedded ----
      # PlatformIO still fetches its own toolchains into ~/.platformio at first
      # run — this pins the entry point, not the whole toolchain. Serial access
      # needs the `dialout` group; see modules/nixos/core/users.nix.
      platformio # ESP32 build/upload driver
      esptool # flashing and merge_bin, standalone from PlatformIO's bundled copy

      # ---- Game dev ----
      furnace # chiptune tracker

      # ---- Notes ----
      obsidian # markdown knowledge base (unfree; allowUnfree is set globally)

      # ---- Media ----
      # Streams a desktop or a game from anything running Sunshine or
      # GeForce Experience on the LAN.
      moonlight-qt
      mpv
      spotify # official client (unfree; allowUnfree is set globally)

      # ---- Viewers ----
      imv # vim-keybinding, Wayland-native image viewer
    ];
  };
}
