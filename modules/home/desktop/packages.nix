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
      openscad # programmatic CAD
      krita # digital painting
      inkscape # vector graphics

      # ---- Game dev ----
      furnace # chiptune tracker

      # ---- Notes ----
      obsidian # markdown knowledge base (unfree; allowUnfree is set globally)

      # ---- Media ----
      mpv

      # ---- Viewers ----
      imv # vim-keybinding, Wayland-native image viewer
    ];
  };
}
