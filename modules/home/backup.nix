{ config, lib, pkgs, ... }:

# Off-machine backup via rclone.
#
# rclone rather than a sync daemon (abraunegg/onedrive, the OneDrive client):
# this is one-way archival of directories that already live on disk, not a
# mirrored folder. rclone does not need a local copy of what it uploads, runs
# unattended from a timer, and can talk to any of ~70 backends if OneDrive ever
# stops being the answer.
#
# One-time setup, needs a browser for the OAuth redirect:
#
#   rclone config
#     n) New remote  →  name: onedrive  →  storage: onedrive
#     ...accept the defaults, log in when the browser opens
#
# The resulting token lives in ~/.config/rclone/rclone.conf. It is credentials,
# so it is deliberately NOT in this repo; move it into sops if you ever want a
# new machine to inherit it (see modules/nixos/core/secrets.nix).

let
  cfg = config.jonny.backup;
in
{
  options.jonny.backup = {
    enable = lib.mkEnableOption "rclone-based off-machine backup" // { default = true; };

    remote = lib.mkOption {
      type = lib.types.str;
      default = "onedrive";
      description = "Name of the rclone remote, as created by `rclone config`.";
    };

    destination = lib.mkOption {
      type = lib.types.str;
      default = "backup/optiplex";
      description = "Path within the remote to write to.";
    };

    paths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "/mnt/data/jonny/Camera" ];
      description = ''
        Absolute paths to back up. Each is uploaded to
        <remote>:<destination>/<basename>.

        Deliberately a short list: this is for what cannot be regenerated.
        Anything reproducible from a flake, a git remote or a package manager
        does not belong here.
      '';
    };

    schedule = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "daily";
      description = ''
        systemd calendar expression for automatic runs, or null to leave the
        backup manual. Start with null: run it by hand until you trust it.
      '';
    };

    exclude = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      # NOTE the pattern form: rclone matches a pattern at *any* depth unless it
      # starts with `/`. A `**/` prefix therefore does the opposite of what it
      # looks like — it requires at least one directory level before the name,
      # so `**/.thumbnails/**` silently fails to match `.thumbnails/` sitting at
      # the root of a copied directory. Which is exactly what it did here.
      default = [
        ".direnv/**"
        "node_modules/**"
        ".git/**"
        ".cache/**"
        "result"
        "result-*"

        # Regenerable image caches. Worth excluding for speed as much as size:
        # Camera holds 3712 thumbnails against 2365 real photos, and each tiny
        # file costs a full API round-trip, so they dominate the runtime while
        # contributing 2% of the bytes.
        ".thumbnails/**"
        ".trash/**"
        "Thumbs.db"
        ".DS_Store"
      ];
      description = ''
        Baseline rclone filter patterns applied to every path. Setting this
        replaces the defaults — to add host-specific patterns, use
        `extraExclude` instead, which appends.

        Prefer backing up a whole directory and excluding the reproducible
        parts, over listing the interesting subdirectories: an allow-list
        silently misses whatever you forget, and what you forget is discovered
        only when you need the backup. This list started as an allow-list and
        omitted a password database.
      '';
    };

    extraExclude = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "git/**" ];
      description = ''
        Host-specific patterns, appended to `exclude`. Separate option so a
        host adding one pattern does not silently drop the shared defaults —
        which is exactly what happened when this was a single list.
      '';
    };

    bandwidthLimit = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "08:00,400k 23:00,off";
      description = ''
        Passed to `rclone --bwlimit`. This uplink is 5.7 Mbit/s (~715 KB/s),
        and a saturated uplink stalls *downloads* too, because TCP ACKs queue
        behind the outbound data — the connection feels broken, not merely
        busy.

        The default is a timetable: 400 KB/s from 08:00 (a little over half the
        uplink, leaving the rest usable), unrestricted from 23:00. Set to null
        to always run at full speed.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.rclone

      (pkgs.writeShellApplication {
        name = "backup-now";
        runtimeInputs = [ pkgs.rclone pkgs.libnotify ];
        text = ''
          dest="${cfg.remote}:${cfg.destination}"

          if ! rclone listremotes | grep -qx "${cfg.remote}:"; then
            echo "No rclone remote named '${cfg.remote}'. Run: rclone config" >&2
            exit 1
          fi

          # `copy`, not `sync`: sync deletes anything at the destination that is
          # no longer local, which turns an accidental local deletion into a
          # backup that no longer has the file either.
          #
          # Paths are processed in the order declared, so put the small
          # irreplaceable things first — on a slow uplink the large ones can
          # take days, and you want the important bits safe within the hour.
          for path in ${lib.escapeShellArgs cfg.paths}; do
            [ -e "$path" ] || { echo "skip (missing): $path"; continue; }
            echo "==> $path"
            rclone copy "$path" "$dest/$(basename "$path")" \
              --progress \
              ${lib.optionalString (cfg.bandwidthLimit != null)
                ''--bwlimit ${lib.escapeShellArg cfg.bandwidthLimit} \''}
              --transfers 4 \
              --checkers 8 \
              --retries 5 \
              --low-level-retries 10 \
              --order-by size,ascending \
              ${lib.concatMapStringsSep " \\\n              "
                (p: "--exclude ${lib.escapeShellArg p}") (cfg.exclude ++ cfg.extraExclude)}
          done

          notify-send "Backup" "Finished uploading to $dest" 2>/dev/null || true
        '';
      })
    ];

    systemd.user = lib.mkIf (cfg.schedule != null) {
      services.backup = {
        Unit.Description = "Off-machine backup via rclone";
        Service = {
          Type = "oneshot";
          ExecStart = "${config.home.homeDirectory}/.nix-profile/bin/backup-now";
        };
      };

      timers.backup = {
        Unit.Description = "Scheduled off-machine backup";
        Timer = {
          OnCalendar = cfg.schedule;
          Persistent = true; # catch up after the machine was off
        };
        Install.WantedBy = [ "timers.target" ];
      };
    };
  };
}
