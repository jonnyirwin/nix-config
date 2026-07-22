{ config, pkgs, ... }:

# ============================================================
# Core packages installed globally in your home environment
# ============================================================
#
# These are tools you want available everywhere. Note:
#   - bat, lazygit, zathura, btop → moved to modules/programs.nix
#     (they use HM program modules for catppuccin theming)
#   - Language-specific tools → modules/dev/*.nix
#   - Project-specific tools  → devShells.nix (via `nix develop`)
# ============================================================

{
  home.packages = with pkgs; [

    # ----------------------------------------------------------
    # Modern CLI replacements
    # ----------------------------------------------------------
    eza          # ls with icons + git status (aliased in home.nix)
    fd           # find replacement — fast, .gitignore-aware
    ripgrep      # grep replacement — very fast, .gitignore-aware
    sd           # sed replacement — simpler substitution syntax: sd 'foo' 'bar'
    dust         # du replacement — visual disk usage tree
    procs        # ps replacement — human-readable, coloured output
    jq           # JSON processor — pipe JSON through filters
    yq-go        # YAML/TOML/XML processor — same syntax as jq

    # ----------------------------------------------------------
    # Navigation and search
    # ----------------------------------------------------------
    broot        # interactive directory tree + fuzzy finder
    tre-command  # tree with git-awareness (cmd: tre)

    # ----------------------------------------------------------
    # Git ecosystem
    # ----------------------------------------------------------
    delta        # diff pager (configured in git.nix via programs.git.extraConfig)
    # lazygit is in programs.nix (needs catppuccin theming via HM module)

    # ----------------------------------------------------------
    # Nix tooling
    # ----------------------------------------------------------
    # nix-index: builds a local database of every file in nixpkgs.
    # Enables two powerful commands:
    #   nix-locate <binary>      → which package provides this file?
    #   nix-locate --whole-name ripgrep → exact filename search
    nix-index

    # comma: run ANY nixpkgs binary without installing it.
    # Usage: , cowsay hello    → downloads cowsay temporarily and runs it
    #        , deno run app.ts → use deno without `nix shell` boilerplate
    # Internally uses nix-index to resolve the package name.
    comma

    # ----------------------------------------------------------
    # File management
    # ----------------------------------------------------------
    yazi         # terminal file manager (config symlinked in desktop.nix)

    # ----------------------------------------------------------
    # Clipboard and Wayland
    # ----------------------------------------------------------
    wl-clipboard     # wl-copy / wl-paste (used by tmux copy-mode)
    wl-clip-persist  # keeps clipboard alive after apps close
    cliphist         # clipboard history daemon

    # ----------------------------------------------------------
    # Development utilities
    # ----------------------------------------------------------
    just         # command runner (justfiles — like make but readable)
    jless        # pager for JSON — navigate JSON interactively like less
    miller       # CSV/TSV/JSON/NDJSON data processor — swiss army knife
    httpie       # friendly HTTP client: `http GET api.example.com/users`
    curl         # the classic
    wget         # recursive downloads
    nmap         # network scanner / open port checker

    # ----------------------------------------------------------
    # Process and system inspection
    # ----------------------------------------------------------
    lsof         # list open files and network sockets
    strace       # trace system calls (invaluable for debugging)
    pstree       # show process parent/child tree
    # btop is in programs.nix (HM module for catppuccin theming)

    # ---- Hardware inspection ----
    dmidecode    # read DMI/SMBIOS: RAM sticks, max capacity, board, BIOS
    pciutils     # lspci — enumerate PCI devices (GPU, NVMe, Wi-Fi card)
    usbutils     # lsusb — enumerate USB devices
    nvme-cli     # nvme — inspect/manage NVMe SSDs (health, temp, namespaces)

    # ----------------------------------------------------------
    # Archive tools
    # ----------------------------------------------------------
    unzip
    p7zip

    # ----------------------------------------------------------
    # Fonts
    # ----------------------------------------------------------
    # Symbols Nerd Font: provides the icon ranges mapped in kitty.conf.
    # Your main font (Dank Mono, proprietary) must be installed manually:
    #   mkdir -p ~/.local/share/fonts && cp DankMono*.otf ~/.local/share/fonts/
    # Until you do, the fontconfig alias in modules/desktop.nix silently
    # resolves "Dank Mono" to Intel One Mono, so kitty still looks right.
    # The activation.nix fc-cache script runs after font packages are installed.
    nerd-fonts.symbols-only

    # ----------------------------------------------------------
    # Applications
    # ----------------------------------------------------------
    # firefox → now managed via programs.firefox in modules/desktop.nix
    #           so the 1Password extension can be force-installed by policy.
    claude-code  # Anthropic's agentic CLI — installed declaratively (not `nix run`)

    # ----------------------------------------------------------
    # Misc utilities
    # ----------------------------------------------------------
    playerctl    # MPRIS media player control (waybar integration)
    brightnessctl # screen brightness control
    libnotify    # notify-send command for desktop notifications
    imagemagick  # image processing CLI (used by some Sway scripts)
    ffmpeg       # video/audio transcoding
    pulsemixer   # TUI audio mixer (config symlinked in desktop.nix)
    pavucontrol  # GTK audio control panel (GUI fallback for PulseAudio)
  ];
}
