{
  catppuccin.lazygit.enable = true;

  programs.lazygit = {
    enable = true;
    settings = {
      gui.nerdFontsVersion = "3";

      keybinding.universal = {
        scrollDownMain-alt1 = "<c-d>";
        scrollUpMain-alt1 = "<c-u>";
      };

      # Commit signing goes through git's own config (SSH via 1Password), so
      # lazygit must not try to drive gpg itself.
      git.overrideGpg = false;

      git.paging = {
        colorArg = "always";
        pager = "delta --dark --paging=never";
      };
    };
  };
}
