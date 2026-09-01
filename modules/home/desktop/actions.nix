{ lib, config, pkgs, ... }:

let
  cfg = config.jonny.desktop;

  term = lib.getExe pkgs.kitty;

  # Wraps a scratchpad's command in a loop, so quitting the program inside the
  # window leaves the window there rather than destroying it. A command that
  # exits immediately would spin this into a fork bomb, so anything that ran
  # for less than a second earns a pause before the retry.
  respawn = cmd: "${lib.getExe pkgs.bash} -c 'while true; do start=$SECONDS; ${cmd} || true; if [ $((SECONDS - start)) -lt 1 ]; then sleep 1; fi; done'";

  scratchpadType = lib.types.submodule {
    options = {
      key = lib.mkOption {
        type = lib.types.str;
        description = "Binding that summons and dismisses it, spoken form.";
      };
      id = lib.mkOption {
        type = lib.types.str;
        description = ''
          The window's app_id. The compositor's window rules key off this, so
          it has to match what `command` actually sets.
        '';
      };
      width = lib.mkOption { type = lib.types.int; description = "Floating width."; };
      height = lib.mkOption { type = lib.types.int; description = "Floating height."; };
      command = lib.mkOption {
        type = lib.types.str;
        description = "What to run the first time the binding is pressed.";
      };
    };
  };
in
{
  # Keys and scratchpads live here rather than in the sway config because they
  # have more than one reader: the compositor binds them, the command menu
  # prints them beside its entries, and the cheatsheet lists them. Declaring
  # them once means a rebind cannot leave two of those three describing a key
  # that no longer does anything.
  #
  # Nothing here is compositor-specific. The spoken form ("Mod+Shift+S") is
  # translated to sway's own spelling by lib's `swayBinding` at the point of
  # use, so a second compositor would bring its own translation and read the
  # same declarations.
  options.jonny.desktop = {
    keys = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      description = ''
        Bindings by what they do, written the way they are spoken: modifiers
        `Mod`, `Shift`, `Ctrl`, `Alt`, then the key, joined with `+`.

        Only the hand-chosen ones are here. Focus, window movement, workspace
        switching and output movement are generated from a direction or a
        number in the compositor config and have no name worth giving.
      '';
      default = {
        # ---- Basics ----
        terminal = "Mod+Return";
        kill = "Mod+Shift+Q";
        launcher = "Mod+D";
        reload = "Mod+Shift+C";
        commandMenu = "Mod+Ctrl+Space";
        windowSwitcher = "Mod+Tab";
        toggleBar = "Mod+O";
        voiceInput = "Mod+;";

        # ---- Session ----
        powerMenu = "Mod+Shift+E";
        lockScreen = "Mod+Shift+X";
        networkMenu = "Mod+Shift+N";
        idleInhibitor = "Mod+I";
        pomodoro = "Mod+P";

        # ---- Clipboard ----
        clipboardHistory = "Mod+C";
        pastePrimary = "Mod+Shift+V";
        notificationReplay = "Mod+Shift+,";

        # ---- Capture and pickers ----
        screenshotRegion = "Mod+S";
        screenshotAnnotate = "Mod+Shift+S";
        emojiPicker = "Mod+.";
        ocrRegion = "Mod+Shift+O";
        qrDecode = "Mod+Shift+G";
        colorPicker = "Mod+Shift+P";
        recordToggle = "Mod+Shift+R";

        # ---- Audio and media ----
        volumeUp = "Mod+Alt+K";
        volumeDown = "Mod+Alt+J";
        volumeMute = "Mod+Alt+M";
        mediaNext = "Mod+Alt+.";
        mediaPrevious = "Mod+Alt+,";
        mediaPlayPause = "Mod+Alt+Space";

        # ---- Display ----
        brightnessUp = "Mod+Alt+L";
        brightnessDown = "Mod+Alt+H";
        displayLayout = "Mod+Shift+D";
        screenRotate = "Mod+Ctrl+R";
        wallpaper = "Mod+W";

        # ---- Layout ----
        splitHorizontal = "Mod+B";
        splitVertical = "Mod+V";
        toggleSplit = "Mod+E";
        fullscreen = "Mod+F";
        floatingToggle = "Mod+Shift+Space";
        focusModeToggle = "Mod+Space";
        focusParent = "Mod+A";
        focusChild = "Mod+Ctrl+A";
        resizeMode = "Mod+R";

        # ---- Scratchpad ----
        scratchpadMove = "Mod+Shift+-";
        scratchpadShow = "Mod+-";

        # The named scratchpads' keys live here, not in `scratchpads` below,
        # because the cheatsheet lists them and the cheatsheet is one of the
        # scripts that `scratchpads` is built from. Pure strings have no such
        # loop to get caught in.
        scratchpadMixer = "Mod+M";
        scratchpadBtop = "Mod+T";
        scratchpadNotes = "Mod+N";
        scratchpadYazi = "Mod+Y";
        scratchpadCheatsheet = "Mod+?";

        # ---- Workspaces ----
        workspaceBackAndForth = "Mod+`";
      };
    };

    scratchpads = lib.mkOption {
      type = lib.types.attrsOf scratchpadType;
      description = ''
        Floating windows parked in the scratchpad, summoned by their own key.
        They are deliberately not pre-launched: each one is a terminal, and
        starting five at login costs memory and a burst of work for windows
        that may never be summoned. The toggle script creates one on first
        press instead — one slower summon, then it stays resident for the rest
        of the session.
      '';
      default = {
        mixer = {
          key = cfg.keys.scratchpadMixer;
          id = "float-mixer";
          width = 900;
          height = 500;
          command = "${term} --class=float-mixer ${lib.getExe pkgs.pulsemixer}";
        };

        btop = {
          key = cfg.keys.scratchpadBtop;
          id = "float-btop";
          width = 1200;
          height = 900;
          command = "${term} --class=float-btop ${respawn (lib.getExe pkgs.btop)}";
        };

        notes = {
          key = cfg.keys.scratchpadNotes;
          id = "float-notes";
          width = 1000;
          height = 700;
          command = "${term} --class=float-notes nvim ${config.home.homeDirectory}/notes/scratch.md";
        };

        yazi = {
          key = cfg.keys.scratchpadYazi;
          id = "float-yazi";
          width = 1200;
          height = 800;
          command = "${term} --class=float-yazi ${lib.getExe pkgs.yazi}";
        };

        cheatsheet = {
          key = cfg.keys.scratchpadCheatsheet;
          id = "float-cheatsheet";
          width = 960;
          height = 640;
          command = "${term} --class=float-cheatsheet ${respawn (lib.getExe cfg.scripts.cheatsheet)}";
        };
      };
    };
  };
}
