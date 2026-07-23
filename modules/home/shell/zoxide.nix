{
  # Adds `z` for frecency-based jumping. Deliberately not `--cmd cd`: replacing
  # the builtin breaks scripts that rely on POSIX cd semantics.
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };
}
