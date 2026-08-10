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

    # Enabling the daemon alone is not enough: the login keyring is created
    # locked, and a locked keyring refuses reads exactly like a missing one. The
    # PAM module unlocks it with the password already being typed at the
    # greeter, which is SDDM here (modules/nixos/desktop/sddm.nix) — so this has
    # to name that service, and it only takes effect on a fresh login rather
    # than at rebuild time.
    security.pam.services.sddm.enableGnomeKeyring = true;
  };
}
