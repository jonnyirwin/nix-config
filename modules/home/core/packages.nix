{ pkgs, ... }:

# Tools wanted in every shell. Note what is deliberately NOT here:
#   * LSPs, formatters, linters  → modules/home/editor/neovim.nix (extraPackages,
#     so they are on nvim's PATH only, not polluting the global profile)
#   * language runtimes          → devshells/ via direnv
#   * anything with an HM module → its own module, for theming/config
{
  home.packages = with pkgs; [
    # ---- Modern CLI replacements ----
    eza # ls, with icons and git status
    fd # find
    ripgrep # grep
    sd # sed, for simple substitutions
    jq # JSON
    yq-go # YAML/TOML/XML, jq syntax

    # ---- Git ecosystem ----
    delta # diff pager, configured in git.nix

    # ---- Nix tooling ----
    nix-index # `nix-locate <binary>` — which package ships this file?
    comma # `, cowsay hello` — run any nixpkgs binary without installing
    nix-tree # inspect why something is in the closure

    # ---- Development utilities ----
    just
    curl
    wget
    poppler-utils # pdftotext, pdfinfo

    # ---- Disk and process inspection ----
    dua # interactive disk usage; `dua i <dir>` to walk and delete
    lsof
    strace
    pstree

    # ---- Hardware inspection ----
    dmidecode
    pciutils
    usbutils
    nvme-cli
    # Serial console. Reconnects automatically when the device re-enumerates,
    # which is what you want across an ESP32 reset. Needs the `dialout` group.
    tio

    # ---- Archives ----
    unzip
    p7zip

    # ---- Applications ----
    claude-code
  ];
}
