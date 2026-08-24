{ lib, config, ... }:

# GNOME Keyring — the freedesktop Secret Service (org.freedesktop.secrets)
# provider for the session.
#
# GNOME and Plasma ship a keyring daemon as part of the desktop; sway does not,
# so without this nothing owns org.freedesktop.secrets and any client asking for
# it gets a bare D-Bus `ServiceUnknown` / "The name is not activatable".
#
# 1Password (modules/nixos/desktop/onepassword.nix) is the client that cares
# here. It persists its device/2FA token in the Secret Service, and when the bus
# name is unreachable it degrades quietly rather than failing loudly: MFA is
# still accepted, but the token is never saved and every launch re-prompts,
# leaving only this in ~/.config/1Password/logs —
#
#   Failed to save an account's 2FA token with an error of SystemKeyringError(
#     ... "org.freedesktop.DBus.Error.ServiceUnknown" ...).
#   2FA will only be valid for this unlock session!
let
  cfg = config.jonny.desktop;
in
{
  config = lib.mkIf cfg.enable {
    services.gnome.gnome-keyring.enable = true;

    # gnome-keyring pulls in gcr-ssh-agent, which must not come with it. Its
    # socket unit ends with
    #
    #   ExecStartPost=-systemctl --user set-environment SSH_AUTH_SOCK=%t/gcr/ssh
    #
    # so merely enabling the Secret Service silently repoints SSH_AUTH_SOCK for
    # the whole systemd user manager. modules/home/onepassword.nix puts the
    # 1Password socket in home.sessionVariables, which only reaches the *shell*
    # — the result is a split session where a terminal authenticates via
    # 1Password and anything started by systemd or D-Bus activation talks to an
    # empty gcr agent instead. That is precisely the intermittent "Permission
    # denied (publickey)" the assertion in onepassword.nix exists to prevent;
    # it just could not see this route in. Nothing here wants a second agent —
    # the Secret Service is the only reason gnome-keyring is enabled at all.
    services.gnome.gcr-ssh-agent.enable = false;

    # Enabling the daemon alone is not enough: the login keyring is created
    # locked, and a locked keyring refuses reads exactly like a missing one. The
    # PAM module unlocks it with the password already being typed at the
    # greeter, which is SDDM here (modules/nixos/desktop/sddm.nix) — so this has
    # to name that service, and it only takes effect on a fresh login rather
    # than at rebuild time.
    security.pam.services.sddm.enableGnomeKeyring = true;

    # ...and PAM alone is not enough either, which is the second half of the
    # same trap. pam_gnome_keyring starts the daemon in *login mode*: it takes
    # the stashed password, unlocks login.keyring, then parks on
    # $XDG_RUNTIME_DIR/keyring/control and waits for the session to finish
    # initialising it with `gnome-keyring-daemon --start`. GNOME's session
    # manager does that; sway has no equivalent, so the half-started daemon
    # times out and exits with the unlocked keyring still in it.
    #
    # Nothing then owns org.freedesktop.secrets until the first client asks for
    # it — hours into the session, at which point D-Bus activates a *fresh*
    # daemon that finds no control socket to inherit
    # (`discover_other_daemon: 0`), starts cold, and prompts via gcr for a
    # password already given at the greeter. The symptom is a keyring that is
    # never unlocked at login, no matter how correct the PAM line above is.
    #
    # This unit is the missing `--start`. graphical-session-pre.target comes up
    # in the same second as the PAM session, well inside the login daemon's
    # timeout, so it takes over the already-unlocked instance instead of
    # racing D-Bus activation to start a locked one. If it ever does find no
    # daemon to adopt, it starts one itself and the bus name is still served.
    #
    # Components: secrets only. `ssh` is deliberately absent — 1Password serves
    # the SSH agent (modules/home/services.nix, modules/home/ssh.nix), and two
    # agents fighting over SSH_AUTH_SOCK is how that breaks intermittently.
    systemd.user.services.gnome-keyring = {
      description = "GNOME Keyring (Secret Service)";
      partOf = [ "graphical-session-pre.target" ];
      wantedBy = [ "graphical-session-pre.target" ];
      serviceConfig = {
        # The setuid wrapper, not the bare binary: gnome-keyring wants
        # CAP_IPC_LOCK to keep secrets out of swap, and services.gnome.
        # gnome-keyring.enable is what defines this wrapper.
        ExecStart = "${config.security.wrapperDir}/gnome-keyring-daemon --start --foreground --components=secrets";
        Restart = "on-abort";
      };
    };
  };
}
