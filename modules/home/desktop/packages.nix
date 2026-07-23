{ config, lib, pkgs, ... }:

let
  cfg = config.jonny.desktop;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      # ---- Wayland session ----
      swaybg # wallpaper, driven by the random-wallpaper script
      swayidle # idle timeouts (configured in sway.nix's extraConfig)
      autotiling # automatic split direction
      wdisplays # GUI output configurator, bound to Mod+Shift+D
      wlopm # wlr-output-power-management
      wtype # synthesise keystrokes (emoji picker, PRIMARY paste)

      # ---- Capture ----
      grim
      slurp
      wf-recorder
      flameshot # screenshot annotation (Mod+Shift+S, via screenshot-annotate)
      tesseract # OCR

      # ---- Clipboard ----
      wl-clipboard
      wl-clip-persist # keeps the clipboard alive after the source app exits
      cliphist # clipboard history

      # ---- Audio ----
      pulsemixer
      pavucontrol
      pamixer
      playerctl
      # pactl, for scripts that speak the PulseAudio protocol to PipeWire's shim
      pulseaudio

      # ---- Misc desktop tools ----
      brightnessctl
      libnotify # notify-send
      hyprpicker # Wayland colour picker
      imagemagick # used by the colour picker script
      ffmpeg
      udiskie # automount removable media
      rofimoji # emoji picker backend
    ];
  };
}
