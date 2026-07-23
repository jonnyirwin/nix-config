{ config, lib, ... }:

let
  flavor = config.jonny.theme.flavor;
  # delta names its bundled themes with a capitalised flavour, e.g.
  # "Catppuccin Mocha".
  deltaTheme = "Catppuccin ${lib.toUpper (builtins.substring 0 1 flavor)}${builtins.substring 1 (-1) flavor}";
in
{
  programs.git = {
    enable = true;

    # Commit signing via SSH, backed by the 1Password agent.
    # `key` is the public half of the 1Password "Bearnagh SSH Key"; the private
    # key never touches disk — `op-ssh-sign` asks 1Password to produce the
    # signature (with a desktop approval prompt). The same key authenticates
    # to GitHub via the agent (see modules/home/ssh.nix IdentityAgent).
    signing = {
      format = "ssh";
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP6XbyUKquA4YBu3pKfFlOrDOIIbrj7o4tYpWFZ+3NOV";
      signByDefault = true;
      signer = "/run/current-system/sw/bin/op-ssh-sign";
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
