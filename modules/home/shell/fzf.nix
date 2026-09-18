{ config, lib, ... }:

let
  p = config.jonny.theme.palette;
in
{
  # Colours are written explicitly rather than via catppuccin.fzf.enable so the
  # accent slots (prompt, pointer) follow jonny.theme.accent. This is the same
  # split the old config.fish did by hand between `# >>> catppuccin-accent`
  # markers — now derived instead of rewritten.
  programs.fzf = {
    enable = true;
    enableFishIntegration = true;

    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    fileWidget.command = "fd --type f --hidden --follow --exclude .git";

    defaultOptions = [
      "--height 40%"
      "--layout=default"
      "--border=none"
      "--prompt='❯ '"
      "--pointer=❯"
      "--marker=❯"
      "--color=bg:${p.bg},bg+:${p.surfaceAlt},fg:${p.fg},fg+:${p.fg}"
      "--color=hl:${p.info},hl+:${p.info}"
      "--color=prompt:${p.accent},pointer:${p.accent},marker:${p.success}"
      "--color=spinner:${p.accent},info:${p.surfaceActive},header:${p.info}"
    ];
  };

  # HM exports FZF_DEFAULT_OPTS as a session variable, which is read once at
  # login and inherited from then on — a theme switch would not reach fzf
  # until the next login. Re-exporting per shell picks it up on a new terminal.
  programs.fish.interactiveShellInit = ''
    set -gx FZF_DEFAULT_OPTS ${lib.escapeShellArg config.home.sessionVariables.FZF_DEFAULT_OPTS}
  '';
}
