{ config, lib, ... }:

let
  myLib = import ../../lib { inherit lib; };

  # delta renders through bat's theme set, so this follows jonny.theme.scheme
  # rather than naming Catppuccin.
  deltaTheme = myLib.batThemes.${config.jonny.theme.scheme};
in
{
  programs.git = {
    enable = true;

    # Commit signing goes through the 1Password agent, declared once in
    # modules/home/onepassword.nix along with the SSH auth socket and the
    # allowed-signers file used to verify these signatures.
    signing = {
      format = "ssh";
      inherit (config.jonny.onepassword) signer;
      key = config.jonny.onepassword.sshKey;
      signByDefault = true;
    };

    settings = {
      user.name = "Jonny Irwin";
      user.email = "git@jbi.im";
      init.defaultBranch = "main";
      core.editor = "nvim";

      pull.rebase = false; # false = merge on pull (git default)
      push.default = "current"; # push current branch to same-named remote branch

      # delta is scoped to git here rather than exported as $PAGER — see the
      # note in modules/home/shell/fish.nix about why that distinction matters.
      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
      delta = {
        navigate = true; # n/N to move between diff sections
        light = false;
        side-by-side = false;
        syntax-theme = deltaTheme;
      };
      merge.conflictstyle = "diff3"; # show the common ancestor in conflict markers
      diff.colorMoved = "default";
    };

    # The Obsidian vault is the one repo where signing is not merely
    # inconvenient but unenforceable: it is also committed to from an iPhone via
    # a-shell's libgit2, which cannot sign at all. Its history is therefore a
    # permanent mix of signed and unsigned commits no matter what is configured
    # here, so requiring signatures buys nothing and costs two things — an
    # op-ssh-sign desktop approval prompt on every commit, and a dependency on
    # 1Password being unlocked for jonny.vaultSync's hourly unattended timer.
    #
    # Scoped by gitdir so signing stays mandatory everywhere it does real work.
    includes = lib.optional (config.jonny.vaultSync.path != null) {
      condition = "gitdir:${toString config.jonny.vaultSync.path}/";
      contents.commit.gpgsign = false;
    };

    # Global gitignore — things to always ignore regardless of project.
    ignores = [
      # OS artifacts
      ".DS_Store"
      "Thumbs.db"

      # Editor artifacts
      ".nvim.lua" # project-local neovim config files
      "*.swp"
      "*.swo"
      ".vim/"
      ".idea/"
      "*.iml"
      ".vscode/"

      # Nix
      ".direnv/"
      "result" # nix build output symlink
      "result-*"
      # NOTE: .envrc is deliberately NOT ignored. It is now the mechanism that
      # selects a project's toolchain (`use flake ~/git/nix#ruby`), so hiding it
      # from git status would hide real project config.

      # Secrets / local config
      ".env.local"
      ".env.*.local"
      "*.pem"
      "*.key"
    ];
  };

  # gh — GitHub CLI. Authenticate once with: gh auth login
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      editor = "nvim";
    };
  };
}
