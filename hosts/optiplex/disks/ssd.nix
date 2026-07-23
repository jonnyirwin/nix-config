# Target layout for the SATA SSD: bulk storage, after the OS moves to the NVMe.
#
# Samsung MZ7TE256, 256 GB. Kept in its own file so it can be formatted
# independently of the OS disk — the migration wipes this one last, only after
# the NVMe is running and the data has been copied back off it.
#
# Unencrypted by design: it holds scratch and bulk media, and encrypting it
# would mean a second passphrase at boot for data that does not warrant one.
# Move anything sensitive to /mnt/data, which lives inside the LUKS container.
{
  disko.devices.disk.ssd = {
    type = "disk";
    device = "/dev/disk/by-id/ata-SAMSUNG_MZ7TE256HMHP-000L7_S1K7NSAF616213";

    content = {
      type = "gpt";
      partitions.storage = {
        size = "100%";
        content = {
          type = "filesystem";
          format = "ext4";
          mountpoint = "/mnt/storage";
          # Never block boot on a secondary disk.
          mountOptions = [ "nofail" "x-systemd.device-timeout=5s" ];
        };
      };
    };
  };
}
