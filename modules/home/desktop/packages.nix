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
      wlopm # wlr-output-power-management

      # ---- Clipboard ----
      wl-clipboard # also used interactively, not just by scripts
      wl-clip-persist # keeps the clipboard alive after the source app exits
      cliphist # clipboard history

      # ---- Audio ----
      pulsemixer
      pavucontrol
      pamixer
      playerctl
      # pactl, for anything that speaks the PulseAudio protocol to PipeWire's shim
      pulseaudio

      # ---- Misc desktop tools ----
      brightnessctl
      libnotify # notify-send, used interactively too
      hyprpicker # Wayland colour picker
      ffmpeg

      # ---- Design / engineering ----
      kicad # PCB design
      # The stable `openscad` attr is still the 2021.01 release; the nightly
      # carries the Manifold geometry backend, which is far faster on CSG-heavy
      # models. Same binary name, so nothing downstream changes.
      openscad-unstable # programmatic CAD
      freecad # parametric GUI CAD — sketch-driven work and STEP import, which OpenSCAD cannot do
      qalculate-gtk # unit-aware calculator (does dimensional analysis); the `qalc` CLI lives in libqalculate, not here
      krita # digital painting
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
      mpv

      # ---- Viewers ----
      imv # vim-keybinding, Wayland-native image viewer
      f3d # keyboard-driven 3D viewer — STL, STEP, meshes
    ];
  };
}
