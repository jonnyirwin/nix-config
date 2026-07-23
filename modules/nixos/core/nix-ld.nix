{
  # Installs a real loader at /lib64/ld-linux-x86-64.so.2 (otherwise a stub that
  # only prints an error) so prebuilt generic-Linux executables run without
  # patchelf. Needed by Claude Code's native installer, which self-updates into
  # ~/.local/share/claude/versions/ and so cannot be wrapped.
  programs.nix-ld.enable = true;
}
