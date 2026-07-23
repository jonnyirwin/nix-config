# Both disks. Importing this gives the system its fileSystems, swapDevices and
# LUKS configuration — disko derives all of them from the layout, which is why
# the generated hardware.nix no longer needs to declare any of it.
#
# The two disks are separate files so each can be formatted on its own:
#
#   sudo disko --mode destroy,format,mount ./hosts/optiplex/disks/nvme.nix
#
# formats only the NVMe and leaves the SATA disk untouched. That separation is
# what makes the migration safe — see docs/disk-migration.md.
{
  imports = [
    ./nvme.nix
    ./ssd.nix
  ];
}
