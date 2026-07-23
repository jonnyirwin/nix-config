{ config, ... }:

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
      "--color=bg:${p.base},bg+:${p.surface1},fg:${p.text},fg+:${p.text}"
      "--color=hl:${p.blue},hl+:${p.blue}"
      "--color=prompt:${p.accent},pointer:${p.accent},marker:${p.green}"
      "--color=spinner:${p.accent},info:${p.surface2},header:${p.blue}"
    ];
  };
}
