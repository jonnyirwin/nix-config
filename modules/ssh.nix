{ config, pkgs, ... }:

# ============================================================
# SSH client configuration
# ============================================================
#
# programs.ssh manages ~/.ssh/config. Home Manager generates it
# from Nix attributes, which means:
#   - You can reference nix values (config.home.homeDirectory, etc.)
#   - The file is always in sync with your declared config
#   - Multiple machines can have different SSH configs via hosts/
#
# If you already have an existing ~/.ssh/config, move the entries
# you want to keep into the matchBlocks below and delete the raw file
# (HM will error if the file already exists and wasn't created by HM).
# ============================================================

{
  programs.ssh = {
    enable = true;

    # ----------------------------------------------------------
    # Host blocks (matchBlocks)
    # ----------------------------------------------------------
    # Each entry generates a `Host` block in ~/.ssh/config.
    # The key is the alias used in `ssh <alias>`.
    matchBlocks = {

      # Global defaults (applies to all hosts unless overridden).
      # addKeysToAgent: automatically add keys to the running SSH agent.
      # serverAliveInterval: keepalive every N seconds (prevents idle drops).
      "*" = {
        addKeysToAgent      = "yes";
        serverAliveInterval = 60;
        serverAliveCountMax = 3;
      };

      # GitHub — use SSH key for git operations.
      # After setting this, `git clone git@github.com:user/repo` works
      # without specifying the key explicitly.
      "github.com" = {
        hostname        = "github.com";
        user            = "git";
        # Point at your actual SSH private key.
        # If you use a GPG auth subkey as SSH key, gpg-agent handles this
        # automatically — you don't need an identityFile here.
        # identityFile  = "${config.home.homeDirectory}/.ssh/id_ed25519";
        identitiesOnly = true;   # don't try other keys if the specified one fails
      };

      # ---- Template: remote development server ----
      # Uncomment and fill in when you have a remote machine.
      # "dev-server" = {
      #   hostname     = "192.168.1.100";      # or a domain name
      #   user         = "jonny";
      #   identityFile = "${config.home.homeDirectory}/.ssh/id_ed25519";
      #   # Forward your local gpg-agent so you can sign commits remotely
      #   # without copying your private key to the server:
      #   # extraOptions.RemoteForward = "/run/user/1000/gnupg/S.gpg-agent.extra /run/user/1000/gnupg/S.gpg-agent";
      # };

      # ---- Template: work VPN / bastion host ----
      # "bastion" = {
      #   hostname      = "bastion.company.com";
      #   user          = "jonny";
      #   identityFile  = "${config.home.homeDirectory}/.ssh/id_ed25519_work";
      #   # ProxyJump: connect to "internal-server" via this bastion
      #   # (SSH tunnels through bastion automatically)
      # };
      #
      # "internal-server" = {
      #   hostname      = "10.0.0.50";
      #   user          = "jonny";
      #   proxyJump     = "bastion";
      # };
    };

    # ----------------------------------------------------------
    # Extra SSH options (applies globally unless overridden per-host)
    # ----------------------------------------------------------
    extraConfig = ''
      # Reuse existing connections for the same host (faster repeated connections)
      ControlMaster auto
      ControlPath   ~/.ssh/sockets/%r@%h-%p
      ControlPersist 600

      # Prefer Ed25519 keys (modern, fast, secure) over RSA
      HostKeyAlgorithms ssh-ed25519-cert-v01@openssh.com,ssh-ed25519,rsa-sha2-512,rsa-sha2-256
      PubkeyAcceptedAlgorithms +ssh-ed25519-cert-v01@openssh.com,ssh-ed25519
    '';
  };

  # Create the sockets directory used by ControlPath above
  home.file.".ssh/sockets/.keep".text = "";
}
