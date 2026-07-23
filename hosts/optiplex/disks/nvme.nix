# Target layout for the NVMe: the OS disk.
#
# Samsung MZVLB512HAJQ, 512 GB. Referenced by stable by-id path — never
# /dev/nvme0n1, which is allocation-order dependent.
#
# Shape: ESP + a single LUKS container holding an LVM volume group. One
# passphrase at boot unlocks everything, and root/swap/data can be resized
# later without repartitioning — which the current two-separate-LUKS-devices
# layout on the SATA disk cannot do.
{
  disko.devices = {
    disk.nvme = {
      type = "disk";
      device = "/dev/disk/by-id/nvme-SAMSUNG_MZVLB512HAJQ-000L7_S3TNNE0JC04672";

      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              # Matches the fmask/dmask the current /boot uses; without it
              # systemd-boot warns the ESP is world-readable.
              mountOptions = [ "umask=0077" ];
            };
          };

          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "cryptroot";
              settings.allowDiscards = true; # TRIM through to the SSD
              content = {
                type = "lvm_pv";
                vg = "pool";
              };
            };
          };
        };
      };
    };

    lvm_vg.pool = {
      type = "lvm_vg";
      lvs = {
        root = {
          size = "200G";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };

        swap = {
          # Matches the current 12.5 GB, rounded. Inside LUKS, so encrypted
          # without the separate swap container the old layout needed.
          size = "16G";
          content = {
            type = "swap";
            discardPolicy = "both";
          };
        };

        data = {
          size = "100%FREE";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/mnt/data";
          };
        };
      };
    };
  };
}
