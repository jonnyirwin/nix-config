{ pkgs, ... }:

# Systemd *user* services — they start at login and stop at logout.
#   systemctl --user status <name>
#   journalctl --user -u <name> -f
#
# Desktop services (mako, kanshi) live in modules/home/desktop/ next to their
# configuration.
{
  services.gpg-agent = {
    enable = true;

    defaultCacheTtl = 3600; # since last use
    maxCacheTtl = 86400; # absolute

    # Deliberately OFF. 1Password serves SSH keys via ~/.1password/agent.sock
    # (see modules/home/ssh.nix and the SSH_AUTH_SOCK export in shell/fish.nix).
    # Enabling this would have gpg-agent fight 1Password for the same socket,
    # which surfaces as intermittent "Permission denied (publickey)".
    enableSshSupport = false;

    pinentry.package = pkgs.pinentry-gnome3;
  };

  programs.gpg = {
    enable = true;
    settings = {
      # Short (32-bit) key IDs are collision-prone; always show long ones.
      keyid-format = "0xlong";
      with-fingerprint = true;
      use-agent = true;
    };
  };

  # Peer-to-peer file sync; web UI on http://localhost:8384.
  services.syncthing.enable = true;
}
