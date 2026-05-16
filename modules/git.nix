{ config, pkgs, ... }:

# ============================================================
# Git configuration
# ============================================================
#
# Using Home Manager's native `programs.git` module here (rather
# than symlinking ~/.dotfiles/git/.gitconfig) because:
#
#   1. It generates the gitconfig from Nix attributes, so secrets
#      like your signing key are declared once in Nix and can be
#      overridden per-machine.
#   2. HM can hook into other programs (e.g. programs.gh) more
#      cleanly when it owns the git config.
#   3. The `includes` option lets you layer machine-specific overrides
#      without editing this file.
#
# If you prefer to keep your raw .gitconfig from dotfiles, remove
# this module and add to desktop.nix or packages.nix:
#   home.file.".gitconfig".source = config.lib.file.mkOutOfStoreSymlink
#     "${config.home.homeDirectory}/.dotfiles/git/.gitconfig";
# ============================================================

{
  programs.git = {
    enable = true;

    userName  = "Jonny Irwin";
    userEmail = "git@jbi.im";

    # GPG commit signing — matches your .gitconfig.
    # Ensure gpg-agent is running (Debian: install gnupg2 and add
    # `use-agent` to ~/.gnupg/gpg.conf).
    signing = {
      key    = "B02BA0E451EA374E";
      signByDefault = true;
    };

    extraConfig = {
      init.defaultBranch = "main";
      core.editor = "nvim";    # Use your Neovim, not the old vim alias in dotfiles

      # Rebase-centric workflow defaults — adjust to taste.
      pull.rebase  = false;     # false = merge on pull (git default)
      push.default = "current"; # push current branch to same-named remote branch

      # Delta gives you beautiful diffs in the terminal.
      # Install: included in packages.nix.
      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
      delta = {
        navigate    = true;   # n/N to move between diff sections
        light       = false;  # dark terminal
        side-by-side = false; # set to true if you prefer side-by-side diffs
        syntax-theme = "Catppuccin Mocha";
      };
      merge.conflictstyle = "diff3"; # show the common ancestor in conflict markers
      diff.colorMoved     = "default";
    };

    # Global gitignore — things to always ignore regardless of project.
    ignores = [
      # OS artifacts
      ".DS_Store"
      "Thumbs.db"

      # Editor artifacts
      ".nvim.lua"       # project-local neovim config files
      "*.swp"
      "*.swo"
      ".vim/"
      ".idea/"
      "*.iml"
      ".vscode/"

      # Nix
      ".direnv/"
      ".envrc"          # often project-specific, sometimes not committed
      "result"          # nix build output symlink
      "result-*"

      # Mise
      ".mise.local.toml"

      # Secrets / local config
      ".env.local"
      ".env.*.local"
      "*.pem"
      "*.key"
    ];
  };

  # gh — GitHub CLI, configured to use your git identity automatically.
  # Authenticate once with: gh auth login
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      editor       = "nvim";
    };
  };

  # delta — the diff pager referenced in extraConfig above.
  # It reads the [delta] section from gitconfig automatically.
  home.packages = with pkgs; [
    delta
  ];
}
