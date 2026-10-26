{ lib, config, pkgs, ... }:

let
  cfg = config.jonny.desktop;
in
{
  config = lib.mkIf cfg.enable {
    # System-level because the GUI needs a polkit policy and a setuid helper.
    # This module also installs the browser native-messaging manifests that let
    # the Firefox extension (force-installed in modules/home/firefox.nix) unlock
    # via the desktop app. The same app serves the SSH agent used by
    # modules/home/ssh.nix and commit signing in modules/home/git.nix.
    programs._1password.enable = true; # the `op` CLI
    programs._1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "jonny" ];

      # Nixpkgs patches the main app's RPATH, but not this Chromium helper.
      # Without GLib in its RPATH, crashpad_handler fails before 1Password can
      # finish starting ("libglib-2.0.so.0: cannot open shared object file").
      package = pkgs._1password-gui.overrideAttrs (old: {
        postFixup = (old.postFixup or "") + ''
          patchelf --add-rpath "${lib.makeLibraryPath [ pkgs.glib ]}" \
            "$out/share/1password/chrome_crashpad_handler"
        '';
      });
    };
  };
}
