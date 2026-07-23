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
          for path in ${lib.escapeShellArgs cfg.paths}; do
            [ -e "$path" ] || { echo "skip (missing): $path"; continue; }
            echo "==> $path"
            rclone copy "$path" "$dest/$(basename "$path")" \
              --progress \
              --transfers 8 \
              --checkers 16 \
              --retries 5 \
              --exclude '.direnv/**' \
              --exclude 'node_modules/**' \
              --exclude '**/.git/**'
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
