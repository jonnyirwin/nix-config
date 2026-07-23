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

  stateDir = "\${XDG_STATE_HOME:-$HOME/.local/state}/backup";
  rc = "http://127.0.0.1:${toString cfg.rcPort}";

  backupNow = pkgs.writeShellApplication {
    name = "backup-now";
    runtimeInputs = [ pkgs.rclone pkgs.libnotify pkgs.coreutils pkgs.jq ];
    text = ''
      dest="${cfg.remote}:${cfg.destination}"
      state="${stateDir}"
      mkdir -p "$state"

      if ! rclone listremotes | grep -qx "${cfg.remote}:"; then
        echo "No rclone remote named '${cfg.remote}'. Run: rclone config" >&2
        exit 1
      fi

      # Cleared on exit however we exit, so a killed backup does not leave the
      # waybar module claiming one is still running.
      trap 'rm -f "$state/current"' EXIT INT TERM

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
        basename "$path" > "$state/current"

        # Record the full size of this path so the waybar module can report
        # progress against the *path*, not against whatever is left to do in
        # this particular rclone process. Without it, resuming an almost
        # finished backup displays 0%, because rclone's own totalBytes counts
        # only the work remaining.
        rclone size "$path" --json \
          ${lib.concatMapStringsSep " \\\n          "
            (p: "--exclude ${lib.escapeShellArg p}") (cfg.exclude ++ cfg.extraExclude)} \
          | jq -r '.bytes' > "$state/current-total" || echo 0 > "$state/current-total"

        rclone copy "$path" "$dest/$(basename "$path")" \
          --progress \
          ${lib.optionalString (cfg.bandwidthLimit != null)
            ''--bwlimit ${lib.escapeShellArg cfg.bandwidthLimit} \''}
          --transfers 4 \
          --checkers 8 \
          --retries 5 \
          --low-level-retries 10 \
          --order-by size,ascending \
          --rc --rc-addr 127.0.0.1:${toString cfg.rcPort} --rc-no-auth \
          ${lib.concatMapStringsSep " \\\n          "
            (p: "--exclude ${lib.escapeShellArg p}") (cfg.exclude ++ cfg.extraExclude)}
      done

      date +%s > "$state/last-success"
      notify-send "Backup" "Finished uploading to $dest" 2>/dev/null || true
    '';
  };

  backupStatus = pkgs.writeShellApplication {
    name = "backup-status";
    runtimeInputs = [ pkgs.curl pkgs.jq pkgs.coreutils ];
    text = ''
      # Emits waybar JSON. Reads rclone's remote-control API while a backup is
      # running, and falls back to the age of the last success when it is not.
      state="${stateDir}"

      stats=$(curl -s --max-time 1 -X POST ${rc}/core/stats 2>/dev/null || true)

      if [ -n "$stats" ] && [ "$(jq -r 'has("bytes")' <<<"$stats")" = "true" ]; then
        path=$(cat "$state/current" 2>/dev/null || echo "backup")

        # Progress is measured against the size of the whole path, recorded by
        # backup-now. rclone's own totalBytes counts only what is left to do in
        # this process, so a resumed backup that is nearly finished would
        # otherwise report ~0% — which it did.
        pathTotal=$(cat "$state/current-total" 2>/dev/null || echo 0)

        jq -c -n --argjson s "$stats" --arg path "$path" --argjson pathTotal "$pathTotal" '
          ($s.bytes // 0)                        as $thisRun
        | ($s.totalBytes // 0)                   as $runTotal
        | (($runTotal - $thisRun) | if . < 0 then 0 else . end) as $remaining
        | (if $pathTotal > 0 then $pathTotal else $runTotal end)  as $total
        | (($total - $remaining) | if . < 0 then 0 else . end)    as $done
        | (if $total > 0 then ($done / $total * 100) else 0 end | floor) as $pct
        | ($s.speed // 0)                        as $speed
        | ($s.eta // null)                       as $eta
        | (if $eta == null then "—"
           elif $eta > 3600 then "\(($eta / 3600) | floor)h\((($eta % 3600) / 60) | floor)m"
           elif $eta > 60   then "\(($eta / 60) | floor)m"
           else "\($eta | floor)s" end)          as $etatxt
        | (($done / 1073741824 * 10 | floor) / 10)  as $doneGiB
        | (($total / 1073741824 * 10 | floor) / 10) as $totalGiB
        | {
            text: "󰅧 \($pct)%",
            tooltip: "\($path) — \($doneGiB) of \($totalGiB) GiB (\($pct)%)\nspeed \(($speed / 1024) | floor) KiB/s\neta \($etatxt)",
            class: "running"
          }'
        exit 0
      fi

      # Not running: report how long ago the last one finished.
      if [ ! -r "$state/last-success" ]; then
        jq -c -n '{ text: "󰅧 never", tooltip: "No backup has completed yet", class: "never" }'
        exit 0
      fi

      last=$(cat "$state/last-success")
      age=$(( $(date +%s) - last ))
      days=$(( age / 86400 ))

      if [ "$age" -lt 3600 ]; then ago="$(( age / 60 ))m ago"
      elif [ "$age" -lt 86400 ]; then ago="$(( age / 3600 ))h ago"
      else ago="''${days}d ago"; fi

      if [ "$days" -ge ${toString cfg.staleAfterDays} ]; then class="stale"; else class="ok"; fi

      jq -c -n --arg ago "$ago" --arg class "$class" \
        --arg when "$(date -d "@$last" '+%Y-%m-%d %H:%M')" \
        '{ text: "󰅧 \($ago)", tooltip: "Last backup completed \($when)", class: $class }'
    '';
  };
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

    rcPort = lib.mkOption {
      type = lib.types.port;
      default = 5572;
      description = ''
        Port for rclone's remote-control API, bound to loopback only. It is
        what lets the waybar module read live progress: the alternative is
        scraping --progress output, which is carriage-return animated and
        formatted for humans.
      '';
    };

    staleAfterDays = lib.mkOption {
      type = lib.types.int;
      default = 7;
      description = "Age at which the waybar module flags the last backup as stale.";
    };

    packages = lib.mkOption {
      type = lib.types.attrsOf lib.types.package;
      readOnly = true;
      default = { now = backupNow; status = backupStatus; };
      description = "Referenced by the waybar module; see modules/home/desktop/waybar.nix.";
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
      backupNow
      backupStatus
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
