{ config, lib, pkgs, osConfig ? null, ... }:

# The 1Password SSH agent is the *only* signing and authentication path.
#
# Declared once here so the key, the socket, and the signer binary cannot drift
# apart across git.nix, ssh.nix and shell/fish.nix. Nothing else is permitted to
# answer on SSH_AUTH_SOCK — see the gpg-agent note in services.nix, and the
# assertion at the bottom of this file which enforces it.

let
  cfg = config.jonny.onepassword;
in
{
  options.jonny.onepassword = {
    enable = lib.mkEnableOption "1Password as the sole SSH agent and commit signer" // {
      default = true;
    };

    sshKey = lib.mkOption {
      type = lib.types.str;
      default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP6XbyUKquA4YBu3pKfFlOrDOIIbrj7o4tYpWFZ+3NOV";
      description = ''
        Public half of the 1Password "Bearnagh SSH Key". The private half never
        touches disk: op-ssh-sign asks 1Password to produce signatures, with a
        desktop approval prompt. Used both to sign commits and to authenticate.
      '';
    };

    agentSocket = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.1password/agent.sock";
      description = "Requires \"Use the SSH agent\" enabled in the 1Password app.";
    };

    signer = lib.mkOption {
      type = lib.types.str;
      default = "/run/current-system/sw/bin/op-ssh-sign";
      description = ''
        Comes from programs._1password-gui at the system level, so it is a
        current-system path rather than a store path.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Everything that authenticates over SSH goes through this socket.
    home.sessionVariables.SSH_AUTH_SOCK = cfg.agentSocket;

    # Verification side of commit signing. Without an allowed-signers file,
    # `git log --show-signature` reports "No signature" on commits that are in
    # fact signed, and merges/pulls cannot verify anything.
    programs.git.settings.gpg.ssh.allowedSignersFile =
      toString (pkgs.writeText "git-allowed-signers" ''
        ${config.programs.git.settings.user.email} ${cfg.sshKey}
      '');

    assertions = [
      {
        assertion = !config.services.gpg-agent.enableSshSupport;
        message = ''
          jonny.onepassword requires services.gpg-agent.enableSshSupport = false.
          Both agents bind SSH_AUTH_SOCK, and whichever wins is a race — the
          symptom is intermittent "Permission denied (publickey)".
        '';
      }
      {
        # The system-level counterpart, and the one that actually bit: enabling
        # the Secret Service (modules/nixos/desktop/keyring.nix) drags in
        # gcr-ssh-agent, whose socket unit runs `systemctl --user set-environment
        # SSH_AUTH_SOCK=%t/gcr/ssh`. home.sessionVariables below only reaches the
        # shell, so the two disagree and which agent you get depends on whether
        # the client was launched from a terminal or by systemd/D-Bus.
        #
        # Checking gpg-agent alone left that route wide open — hence this.
        assertion = !(osConfig.services.gnome.gcr-ssh-agent.enable or false);
        message = ''
          jonny.onepassword requires services.gnome.gcr-ssh-agent.enable = false.
          Its socket unit overwrites SSH_AUTH_SOCK in the systemd user manager,
          which home.sessionVariables cannot reach — leaving the shell on the
          1Password agent and every systemd/D-Bus-launched client on gcr's.
        '';
      }
    ];
  };
}
