{ pkgs, config, ... }:

{
  programs.taskwarrior = {
    enable = true;
    package = pkgs.taskwarrior3;

    # Closest built-in theme to the accent used everywhere else (purple) —
    # not palette-driven like fzf.nix/tmux.nix, since taskwarrior has no
    # catppuccin/nix module and hand-rolling one is more than this is worth.
    colorTheme = "dark-violets-256";

    config = {
      "report.active.columns" = [ "id" "start" "entry.age" "priority" "project" "due" "description" "tags" ];
      "report.active.labels" = [ "ID" "Started" "Age" "Priority" "Project" "Due" "Description" "Tags" ];
    };
  };

  home.packages = [ pkgs.timewarrior ];

  # Starts/stops a timewarrior interval whenever a task is started/stopped
  # (`task start`/`task stop`), so tracking follows task state instead of
  # needing its own separate start/stop commands.
  home.file."${config.xdg.dataHome}/task/hooks/on-modify.timewarrior" = {
    source = "${pkgs.timewarrior}/share/doc/timew/ext/on-modify.timewarrior";
    executable = true;
  };
}
