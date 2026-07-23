{ config, lib, ... }:

let
  palette = config.jonny.theme.palette;
in
{
  programs.fish = {
    enable = true;

    # ---- Abbreviations (were conf.d/abbreviations.fish + dev_shortcuts.fish) ----
    # Abbreviations expand in place as you type, so you see the real command.
    shellAbbrs = {
      # Git
      g = "git";
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git pull";
      gd = "git diff";
      gb = "git branch";
      gco = "git checkout";
      gm = "git merge";

      # Git worktrees
      gw = "git worktree";
      gwa = "git worktree add";
      gwl = "git worktree list";
      gwr = "git worktree remove";
      gwp = "git worktree prune";
      gwm = "git worktree move";

      # Navigation and files
      la = "ls -A";
      l = "ls -CF";
      ".." = "cd ..";
      "..." = "cd ../..";
      mkd = "mkdir -p";
      rmf = "rm -rf";
      cp = "cp -i";
      mv = "mv -i";

      # Docker
      d = "docker";
      dc = "docker compose";
      dps = "docker ps";
      di = "docker images";

      # Node
      nr = "npm run";
      ni = "npm install";
      nid = "npm install --save-dev";
      nig = "npm install -g";
      nt = "npm test";
      ns = "npm start";

      # Yarn
      yr = "yarn run";
      ya = "yarn add";
      yad = "yarn add --dev";
      yi = "yarn install";

      # Python
      py = "python3";
      ipy = "ipython";
      serve = "python3 -m http.server";

      # Rails: start the server with rdbg attached on 127.0.0.1:38698
      rdbgs = "bundle exec rdbg -n --open --host 127.0.0.1 --port 38698 -c -- bin/rails server";
    };

    # ---- Functions (were functions/*.fish) ----
    functions = {
      mkcd = {
        description = "Create directory and cd into it";
        body = ''
          mkdir -p $argv[1]
          and cd $argv[1]
        '';
      };

      extract = {
        description = "Extract various archive formats";
        body = ''
          if test (count $argv) -ne 1
              echo "Usage: extract <archive>"
              return 1
          end

          set -l file $argv[1]

          if not test -f $file
              echo "Error: '$file' is not a valid file"
              return 1
          end

          switch $file
              case "*.tar.bz2" "*.tbz2"
                  tar xjf $file
              case "*.tar.gz" "*.tgz"
                  tar xzf $file
              case "*.tar"
                  tar xf $file
              case "*.bz2"
                  bunzip2 $file
              case "*.gz"
                  gunzip $file
              case "*.rar"
                  unrar e $file
              case "*.zip"
                  unzip $file
              case "*.Z"
                  uncompress $file
              case "*.7z"
                  7z x $file
              case "*"
                  echo "Error: '$file' cannot be extracted"
                  return 1
          end
        '';
      };

      backup = {
        description = "Create a backup of a file with timestamp";
        body = ''
          if test (count $argv) -ne 1
              echo "Usage: backup <file>"
              return 1
          end

          set -l file $argv[1]
          set -l timestamp (date +%Y%m%d_%H%M%S)
          cp $file "$file.backup_$timestamp"
          echo "Backup created: $file.backup_$timestamp"
        '';
      };

      gitclean = {
        description = "Delete merged branches, prune remotes, gc";
        body = ''
          echo "Cleaning up git repository..."
          git branch --merged | grep -v "\*\|main\|master\|develop" | xargs -r -n 1 git branch -d
          git remote prune origin
          git gc --aggressive --prune=now
          echo "Repository cleaned!"
        '';
      };

      gitlog = {
        description = "Pretty git log";
        body = ''
          git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit $argv
        '';
      };

      proj = {
        description = "Navigate to project directories quickly";
        body = ''
          set -l project_dirs ~/git ~/projects ~/code ~/dev ~/work

          if test (count $argv) -eq 0
              echo "Available projects:"
              for dir in $project_dirs
                  if test -d $dir
                      for project in $dir/*/
                          echo "  "(basename $project)
                      end
                  end
              end
              return
          end

          for dir in $project_dirs
              if test -d $dir/$argv[1]
                  cd $dir/$argv[1]
                  return
              end
          end

          echo "Project '$argv[1]' not found"
          return 1
        '';
      };

      # Replaces the old `fishconfig` helper. Fish config is generated from Nix
      # now, so editing ~/.config/fish would be pointless (and it is read-only) —
      # this opens the module that generates it instead.
      nixconfig = {
        description = "Edit this Nix configuration";
        body = ''
          cd ${config.home.homeDirectory}/git/nix
          and $EDITOR .
        '';
      };

      sysinfo = {
        description = "Display system information";
        body = ''
          echo "System Information:"
          echo "=================="
          echo "Hostname: "(hostname)
          echo "Kernel:   "(uname -r)
          echo "Arch:     "(uname -m)
          echo "Uptime:   "(uptime -p)
          echo "Shell:    "$SHELL
          echo "Terminal: "$TERM
          echo ""
          echo "Disk Usage:"
          df -h | head -n 1
          df -h | grep -E '^/dev/'
          echo ""
          echo "Memory Usage:"
          free -h
        '';
      };

      weather = {
        description = "Get weather for a location";
        body = ''
          if test (count $argv) -eq 0
              curl -s "wttr.in?format=3"
          else
              curl -s "wttr.in/$argv[1]?format=3"
          end
        '';
      };
    };

    # ---- Non-interactive init ----
    shellInit = ''
      set fish_greeting ""
    '';

    # ---- Interactive init (was the tail of config.fish) ----
    # The starship/zoxide/direnv/fzf init lines that used to live here are gone:
    # each program's HM module writes its own snippet into vendor_conf.d.
    interactiveShellInit = ''
      # Qt5 apps (OpenSCAD, etc.) use qt5ct for theming
      set -gx QT_QPA_PLATFORMTHEME qt5ct

      set -gx LS_COLORS 'di=1;34:ln=1;36:so=32:pi=33:ex=1;32:bd=1;33:cd=1;33:su=0;41:sg=0;46:tw=0;42:ow=0;43:'

      set -g fish_autosuggestion_enabled 1
      set -g fish_color_autosuggestion ${lib.removePrefix "#" palette.surface2} brblack
    '';
  };

  # ---- Environment (was conf.d/environment.fish) ----
  home.sessionVariables = {
    # EDITOR is set by programs.neovim.defaultEditor; setting it here too would
    # be a conflicting definition.
    VISUAL = "nvim";

    # PAGER is the *general* pager and must stay a real pager. delta is a diff
    # pager and is wired in through git's core.pager (see git.nix) — setting it
    # here would break `man`, `systemctl status`, and anything else that pipes.
    PAGER = "less";
    LESS = "-R"; # interpret ANSI colour (delta emits it)

    # Colourful man pages
    LESS_TERMCAP_mb = "\\e[1;32m";
    LESS_TERMCAP_md = "\\e[1;32m";
    LESS_TERMCAP_me = "\\e[0m";
    LESS_TERMCAP_se = "\\e[0m";
    LESS_TERMCAP_so = "\\e[01;33m";
    LESS_TERMCAP_ue = "\\e[0m";
    LESS_TERMCAP_us = "\\e[1;4;31m";

    # 1Password serves SSH keys; gpg-agent's SSH support is off (see services.nix)
    # so there is exactly one agent answering on this socket.
    SSH_AUTH_SOCK = "${config.home.homeDirectory}/.1password/agent.sock";
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
  ];
}
