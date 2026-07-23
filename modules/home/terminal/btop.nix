{
  catppuccin.btop.enable = true;

  programs.btop = {
    enable = true;
    settings = {
      cpu_single_graph = false;
      update_ms = 2000;
      vim_keys = true;
      rounded_corners = true;
    };
  };
}
