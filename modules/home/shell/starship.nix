{ config, lib, ... }:

let
  palette = config.jonny.theme.palette;

  # Powerline Extra half-circle caps (U+E0B6 left, U+E0B4 right) wrap every
  # module in its own surface0 capsule — the same pill vocabulary as waybar,
  # tmux and rofi.
  pill = colour: body: "[](fg:surface0)[ ${body} ](fg:${colour} bg:surface0)[](fg:surface0) ";

  # Every language module renders identically, in sapphire.
  langModules = [
    { name = "dotnet"; symbol = " "; }
    { name = "elixir"; symbol = " "; }
    { name = "elm"; symbol = " "; }
    { name = "haskell"; symbol = " "; }
    { name = "lua"; symbol = " "; }
    { name = "nodejs"; symbol = " "; }
    { name = "ocaml"; symbol = " "; }
    { name = "python"; symbol = " "; }
    { name = "rust"; symbol = " "; }
    { name = "scala"; symbol = " "; }
    { name = "vagrant"; symbol = " "; }
  ];

  langSettings = lib.listToAttrs (map
    ({ name, symbol }: lib.nameValuePair name {
      inherit symbol;
      disabled = false;
      format = pill "sapphire" "$symbol$version";
    })
    langModules);
in
{
  programs.starship = {
    enable = true;
    enableFishIntegration = true;

    settings = {
      add_newline = true;
      palette = "catppuccin";

      format = lib.concatStrings [
        "$username"
        "$directory"
        "$git_branch"
        "$git_status"
        "$dotnet$elixir$elm$haskell$lua$nix_shell$nodejs$ocaml$python$rust$scala$shell$vagrant"
        "$time"
        "$line_break$character"
      ];

      character = {
        error_symbol = "[❯](bold fg:red)";
        success_symbol = "[❯](bold fg:accent)";
        vimcmd_symbol = "[❮](bold fg:accent)";
      };

      username = {
        show_always = true;
        format = pill "teal" " 󰀄 $user";
        style_user = "fg:teal bg:surface0";
        style_root = "fg:red bg:surface0";
      };

      directory = {
        format = pill "peach" "  $path";
        truncation_length = 4;
        truncation_symbol = "…/";
      };

      git_branch = {
        symbol = "";
        format = pill "green" "  $branch";
      };

      git_status = {
        disabled = false;
        format = pill "green" "❲$all_status$ahead_behind❳";
      };

      time = {
        disabled = false;
        # No trailing space: this is the last pill before the line break.
        format = "[](fg:surface0)[ 󰥔 $time ](fg:blue bg:surface0)[](fg:surface0)";
        time_format = "%H:%M";
      };

      nix_shell = {
        disabled = false;
        symbol = " ";
        format = pill "sapphire" "$symbol$state";
      };

      shell.disabled = true;

      # The palette is derived from jonny.theme, so `accent` follows
      # jonny.theme.accent rather than being rewritten by a script.
      palettes.catppuccin = palette;
    }
    // langSettings;
  };
}
