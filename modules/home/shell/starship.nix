{ config, lib, ... }:

let
  palette = config.jonny.theme.palette;

  # Powerline Extra half-circle caps (U+E0B6 left, U+E0B4 right) wrap every
  # module in its own surface capsule — the same pill vocabulary as waybar,
  # tmux and rofi.
  pill = colour: body: "[](fg:surface)[ ${body} ](fg:${colour} bg:surface)[](fg:surface) ";

  # Every language module renders identically.
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
      format = pill "lang" "$symbol$version";
    })
    langModules);
in
{
  programs.starship = {
    enable = true;
    enableFishIntegration = true;

    settings = {
      add_newline = true;
      palette = "theme";

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
        format = pill "session" " 󰀄 $user";
        style_user = "fg:teal bg:surface0";
        style_root = "fg:red bg:surface0";
      };

      directory = {
        format = pill "path" "  $path";
        truncation_length = 4;
        truncation_symbol = "…/";
      };

      git_branch = {
        symbol = "";
        format = pill "git" "  $branch";
      };

      git_status = {
        disabled = false;
        format = pill "git" "❲$all_status$ahead_behind❳";
      };

      time = {
        disabled = false;
        # No trailing space: this is the last pill before the line break.
        format = "[](fg:surface)[ 󰥔 $time ](fg:time bg:surface)[](fg:surface)";
        time_format = "%H:%M";
      };

      nix_shell = {
        disabled = false;
        symbol = " ";
        format = pill "lang" "$symbol$state";
      };

      shell.disabled = true;

      # Starship palettes are flat name→colour maps, so this is an explicit
      # projection of the theme rather than the whole palette attrset (which
      # now nests `hues` and `ansi`). The names are the ones the formats above
      # use, so a reader can see what each segment means.
      palettes.theme = {
        inherit (palette) surface accent;
        session = palette.hues.cyan;
        path = palette.hues.orange;
        git = palette.success;
        lang = palette.hues.blue;
        time = palette.info;
        red = palette.error;
      };
    }
    // langSettings;
  };
}
