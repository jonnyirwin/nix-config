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
    enableDefaultConfig = false;

    # ----------------------------------------------------------
    # Host blocks (settings)
    # ----------------------------------------------------------
    # `programs.ssh.matchBlocks` is deprecated; `settings` is the successor.
    # Each entry generates a `Host` block in ~/.ssh/config (the key is the
    # alias used in `ssh <alias>`). Options use the upstream OpenSSH directive
    # names (PascalCase), e.g. HostName/User instead of hostname/user.
    settings = {

      # Global defaults (applies to all hosts unless overridden).
      # AddKeysToAgent: automatically add keys to the running SSH agent.
      # ServerAliveInterval: keepalive every N seconds (prevents idle drops).
      "*" = {
        # Use the 1Password SSH agent for authentication (keys live in 1Password,
        # not on disk). Requires "Use the SSH agent" enabled in the 1Password app.
        IdentityAgent = "~/.1password/agent.sock";
        AddKeysToAgent = "yes";
        ServerAliveInterval = 60;
        ServerAliveCountMax = 3;
      };

      # GitHub — use SSH key for git operations.
      # After setting this, `git clone git@github.com:user/repo` works
      # without specifying the key explicitly.
      "github.com" = {
        HostName = "github.com";
        User = "git";
        # Keys live in 1Password (IdentityAgent under "*" above), not on disk.
        # IdentitiesOnly must stay false here: with `true` and no IdentityFile,
        # SSH refuses to offer the agent's keys at all, causing
        # "Permission denied (publickey)". Since the 1Password agent serves a
        # single key, there's no risk of trying the "wrong" one.
        # (If you ever add many keys and hit "too many auth failures", set this
        #  back to true AND add IdentityFile pointing to the *public* key file.)
        IdentitiesOnly = false;
      };

      # ---- Template: remote development server ----
      # Uncomment and fill in when you have a remote machine.
      # "dev-server" = {
      #   HostName     = "192.168.1.100";      # or a domain name
      #   User         = "jonny";
      #   IdentityFile = "${config.home.homeDirectory}/.ssh/id_ed25519";
      #   # Forward your local gpg-agent so you can sign commits remotely
      #   # without copying your private key to the server:
      #   # RemoteForward = "/run/user/1000/gnupg/S.gpg-agent.extra /run/user/1000/gnupg/S.gpg-agent";
      # };

      # ---- Template: work VPN / bastion host ----
      # "bastion" = {
      #   HostName      = "bastion.company.com";
      #   User          = "jonny";
      #   IdentityFile  = "${config.home.homeDirectory}/.ssh/id_ed25519_work";
      #   # ProxyJump: connect to "internal-server" via this bastion
      #   # (SSH tunnels through bastion automatically)
      # };
      #
      # "internal-server" = {
      #   HostName      = "10.0.0.50";
      #   User          = "jonny";
      #   ProxyJump     = "bastion";
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
