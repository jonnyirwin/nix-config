{ config, pkgs, lib, ... }:

# ============================================================
# Home Manager activation scripts
# ============================================================
#
# `home.activation` runs shell commands every time you run
# `home-manager switch`. They are meant for setup that can't be
# expressed declaratively — creating directories, seeding databases,
# running one-time installers.
#
# The DAG (directed acyclic graph) system controls ordering:
#   lib.hm.dag.entryAfter ["writeBoundary"] { ... }
#   → runs AFTER HM has written all managed files to disk
#
#   lib.hm.dag.entryBefore ["writeBoundary"] { ... }
#   → runs BEFORE HM writes files (rarely needed)
#
# Scripts run as your user, in a minimal environment. Use full
# paths or reference pkgs explicitly for any binary you need.
#
# Idempotency: activation scripts run on EVERY switch, so always
# guard actions with a condition: `if [ ! -d ... ]; then ... fi`
# ============================================================

{
  home.activation = {

    # NOTE: tmux plugins are no longer installed here. tpm is gone — plugins
    # come from the store via programs.tmux.plugins in modules/tmux.nix.

    # ----------------------------------------------------------
    # Font cache refresh
    # ----------------------------------------------------------
    # After installing new fonts via home.packages (e.g. nerd-fonts),
    # fontconfig needs to rebuild its cache before apps can find them.
    # fc-cache -f forces a full rebuild.
    #
    # This is a no-op if nothing changed (fc-cache checks mtimes).
    refreshFontCache = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if command -v fc-cache > /dev/null 2>&1; then
        fc-cache -f > /dev/null 2>&1 || true
      fi
    '';

    # ----------------------------------------------------------
    # Create XDG screenshot directory
    # ----------------------------------------------------------
    # Your Sway screenshot scripts write to ~/Pictures/Screenshots.
    # HM doesn't create arbitrary directories, so we do it here.
    createScreenshotDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p "${config.home.homeDirectory}/Pictures/Screenshots"
      mkdir -p "${config.home.homeDirectory}/Pictures/Wallpapers"
    '';

    # ----------------------------------------------------------
    # GPG key trust setup reminder
    # ----------------------------------------------------------
    # This doesn't actually set up GPG (that requires interactive steps),
    # but it checks and prints a reminder if your signing key isn't present.
    # The `:` command is a no-op; the echo only fires if gpg is available
    # but the key isn't in the keyring.
    checkGpgKey = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if command -v gpg > /dev/null 2>&1; then
        if ! gpg --list-secret-keys B02BA0E451EA374E > /dev/null 2>&1; then
          echo ""
          echo "⚠  GPG signing key B02BA0E451EA374E not found in keyring."
          echo "   Import it with: gpg --import your-private-key.asc"
          echo "   Then trust it:  gpg --edit-key B02BA0E451EA374E → trust → 5 → quit"
          echo ""
        fi
      fi
    '';

    # ----------------------------------------------------------
    # nix-index database update (weekly)
    # ----------------------------------------------------------
    # nix-index (installed in packages.nix) needs a local database to
    # answer `nix-locate <binary>` queries. Building it takes ~10 minutes
    # on first run. After that it's fast (incremental).
    #
    # This script only runs the update if the database is more than 7 days old,
    # so it doesn't slow down every `hm switch`.
    #
    # You can also run it manually: nix-index
    updateNixIndex = lib.hm.dag.entryAfter ["writeBoundary"] ''
      DB_DIR="${config.home.homeDirectory}/.cache/nix-index"
      DB_FILE="$DB_DIR/files"
      # Only update if db is missing or older than 7 days
      if [ ! -f "$DB_FILE" ] || \
         [ "$(find "$DB_FILE" -mtime +7 2>/dev/null | wc -l)" -gt "0" ]; then
        if command -v nix-index > /dev/null 2>&1; then
          echo "Updating nix-index database (this may take a few minutes)..."
          nix-index > /dev/null 2>&1 &
          echo "nix-index running in background (pid $!)"
        fi
      fi
    '';
  };
}
