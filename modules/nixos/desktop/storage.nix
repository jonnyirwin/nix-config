{ lib, config, ... }:

let
  cfg = config.jonny.desktop;
in
{
  config = lib.mkIf cfg.enable {
    # The actual mount/unmount/eject backend for removable media. udiskie
    # (home-manager, autostarted by sway) and Thunar's device sidebar are both
    # just clients of this over D-Bus — neither touches a device without it.
    services.udisks2.enable = true;

    # GIO's udisks2 volume monitor, plus the userspace filesystems (trash,
    # MTP, archives) GTK file managers expect. Without this, Thunar's
    # "Devices" sidebar never populates even with udisks2 running and
    # automounting fine.
    services.gvfs.enable = true;
  };
}
