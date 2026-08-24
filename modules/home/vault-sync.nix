{ config, lib, pkgs, ... }:

# Keeps the Obsidian vault's git remote continuously current.
#
# The vault is edited on two devices, and the phone syncs manually and
# infrequently. Most merge conflicts came not from genuinely simultaneous edits
# but from the desktop sitting on hours of uncommitted work that only reached
# the remote after the phone had already diverged. Committing on a timer shrinks
# the window in which two-sided divergence is possible; it is not a backup (see
# jonny.backup for that) and not a substitute for the phone syncing.
#
# Everything here is built around one rule: an unattended sync that fails must
# say so. A vault that silently stopped syncing a fortnight ago is indis-
# tinguishable from one that is working, right up until the point where the two
# histories cannot be reconciled on a phone.
#
# With one refinement learned the hard way — "must say so" is not "must shout
# every hour". Failures split in two. Something needing a human (a real content
# conflict, a repo left mid-rebase) notifies immediately. Something that will
# fix itself (1Password locked, offline, remote moved) is logged and counted,
# and only notifies once it has persisted long enough to mean something. An
# alert you have learned to dismiss is worse than no alert, because you believe
# it is covered.

let
  cfg = config.jonny.vaultSync;

  vaultSync = pkgs.writeShellApplication {
    name = "vault-sync";
    runtimeInputs = [ pkgs.git pkgs.openssh pkgs.libnotify pkgs.coreutils ];
    text = ''
      vault=${lib.escapeShellArg (toString cfg.path)}

      fail() {
        echo "vault-sync: $1" >&2
        notify-send -u critical "Vault sync failed" "$1" 2>/dev/null || true
        exit 1
      }

      state="''${XDG_STATE_HOME:-$HOME/.local/state}/vault-sync"
      mkdir -p "$state"

      # Expected, self-healing conditions: 1Password locked, no network, the
      # remote moved mid-run. Nothing is lost — the commit is already local and
      # the next run retries — so these must not raise a notification. An alert
      # that fires every hour during a normal working day is one you learn to
      # dismiss, and it is the same alert that has to land when something
      # genuinely needs you.
      #
      # Silence forever is the other failure, though: it is how a sync quietly
      # stops working for a fortnight. So a long enough run of them escalates.
      soft() {
        local count=0
        # Not `[ -r ... ] && count=...`: under errexit a failing test as a
        # bare statement exits the script, so the very first soft failure
        # would trip the ERR trap and report itself as an unexpected one.
        if [ -r "$state/soft-failures" ]; then
          count=$(cat "$state/soft-failures")
        fi
        count=$((count + 1))
        echo "$count" > "$state/soft-failures"

        echo "vault-sync: $1 (consecutive: $count)" >&2
        if [ "$count" -ge ${toString cfg.escalateAfter} ]; then
          notify-send -u critical "Vault sync stalled" \
            "$1 - $count consecutive failures" 2>/dev/null || true
        fi
        exit 0
      }

      # writeShellApplication sets errexit, so without this an unanticipated
      # failure exits non-zero into the journal and nowhere else — silent, which
      # is the one outcome this unit exists to prevent. Conditions in `if !`
      # tests do not trigger ERR, so the handled cases below still handle
      # themselves.
      trap 'fail "unexpected failure at line $LINENO"' ERR

      cd "$vault" || fail "vault directory is missing: $vault"

      # A previous run may have left the repo mid-operation. Piling another
      # rebase on top turns a recoverable state into an archaeology exercise.
      if [ -d .git/rebase-merge ] || [ -d .git/rebase-apply ] || [ -f .git/MERGE_HEAD ]; then
        fail "repo is mid-rebase or mid-merge and needs manual attention"
      fi

      git add -A
      if ! git diff --cached --quiet; then
        # Unsigned, and not overridden here: modules/home/git.nix turns signing
        # off for this gitdir specifically, so a commit made by hand in the
        # vault behaves identically to one made by this timer. Signing would
        # otherwise raise an op-ssh-sign approval prompt on a machine nobody is
        # sitting at.
        git commit -q -m "auto: $(date -Is)"
      fi

      # Fetch as its own step, rather than letting `git pull --rebase` do it.
      # A combined pull cannot distinguish "the remote is unreachable" from
      # "your notes conflict", and reporting the first as the second sends you
      # looking for a conflict that does not exist. Which it did.
      if ! git fetch -q origin; then
        soft "cannot reach origin - 1Password locked, or offline"
      fi

      # Rebase rather than merge: an hourly timer generating a merge commit per
      # run makes the history unreadable within a week.
      #
      # On conflict, abort rather than leaving the tree in a conflicted state.
      # Obsidian renders whatever is on disk, so conflict markers would appear
      # as note content and could be saved back over the real text. Aborting
      # keeps local work committed and simply leaves the remote unmerged until
      # a human looks — which the notification asks them to do.
      if ! git rebase -q '@{upstream}'; then
        git rebase --abort 2>/dev/null || true
        fail "rebase conflict - local work is committed, remote not merged"
      fi

      # A push failing after a successful fetch means the remote moved between
      # the two, i.e. the phone pushed. Next run picks it up.
      if ! git push -q; then
        soft "push rejected - remote moved since fetch"
      fi

      # Back to normal: forget any run of soft failures.
      rm -f "$state/soft-failures"
    '';
  };
in
{
  options.jonny.vaultSync = {
    enable = lib.mkEnableOption "timed git sync of an Obsidian vault";

    path = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = "/home/jonny/git/Second-Brain";
      description = "Absolute path to the vault's git working tree.";
    };

    schedule = lib.mkOption {
      type = lib.types.str;
      default = "hourly";
      description = ''
        systemd calendar expression for automatic runs.

        Hourly rather than more often: the point is to bound how far the desktop
        can drift from the remote, not to mirror keystrokes. More frequent runs
        mean more commits containing a half-written sentence, and no less
        divergence in practice.
      '';
    };

    escalateAfter = lib.mkOption {
      type = lib.types.int;
      default = 6;
      description = ''
        How many consecutive self-healing failures — a locked 1Password, no
        network — before one is escalated to a desktop notification.

        Six hourly runs is most of a working day. Long enough that locking the
        screen over lunch never notifies, short enough that a sync which has
        genuinely stopped is caught the same day.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.path != null;
        message = "jonny.vaultSync.enable requires jonny.vaultSync.path to be set.";
      }
    ];

    # Also on PATH, so the same code path can be run by hand when a
    # notification says something needs attention.
    home.packages = [ vaultSync ];

    systemd.user = {
      services.vault-sync = {
        Unit = {
          Description = "Sync Obsidian vault with git";
          After = [ "network-online.target" ];
        };
        Service = {
          Type = "oneshot";
          Environment = [
            # Taken from the 1Password module rather than written out again:
            # a second copy of this path is a second thing to forget to change.
            "SSH_AUTH_SOCK=${config.jonny.onepassword.agentSocket}"
            # notify-send needs the session bus, and a user unit does not
            # inherit the shell's environment. %t is XDG_RUNTIME_DIR. Without
            # this the script still runs and still fails correctly — it just
            # fails invisibly, which defeats the point.
            "DBUS_SESSION_BUS_ADDRESS=unix:path=%t/bus"
          ];
          ExecStart = lib.getExe vaultSync;
        };
      };

      timers.vault-sync = {
        Unit.Description = "Scheduled Obsidian vault sync";
        Timer = {
          OnCalendar = cfg.schedule;
          Persistent = true; # catch up after the machine was off
        };
        Install.WantedBy = [ "timers.target" ];
      };
    };
  };
}
