# Target layout for the OS disk ONLY.
#
# LITEONIT LCS-256L9S, 256 GB SATA SSD. Referenced by stable by-id path —
# never /dev/sdb, which is allocation-order dependent and which on this
# machine is genuinely ambiguous: the 2 TB archive disk currently enumerates
# as /dev/sda, so the OS disk is the *second* letter. That is exactly the
# situation by-id exists for.
#
# ── The 2 TB disk is deliberately absent from this file ──────────────
# `disko --mode destroy,format,mount` only ever touches devices declared in
# the disko config. The Seagate ST2000DM001 holds ~1.2 TB of archive — iTunes
# and music libraries, ebooks, video, iPhone backups, and full home captures
# from several retired machines — with nowhere to stage it. Leaving it
# undeclared is what makes it *impossible* for the install to format it, which
# is a stronger guarantee than remembering not to.
#
# It is mounted instead, by hand, in ../default.nix. That is a documented
# exception to this repo's "disko is the single source of truth for mounts"
# rule, and the exception is the point: a disk disko does not own must not
# appear here.
{
  disko.devices = {
    disk.os = {
      type = "disk";
      device = "/dev/disk/by-id/ata-LITEONIT_LCS-256L9S-11_2.5_7mm_256GB_TW03YYV35508545T1954";

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
              # Without this systemd-boot warns the ESP is world-readable.
              mountOptions = [ "umask=0077" ];
            };
          };

          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "cryptroot";
              settings.allowDiscards = true; # TRIM through to the SSD

              # No passwordFile: disko's `askPassword` therefore defaults to
              # true and prompts during the install, so the passphrase never
              # lands in a file. See hosts/bearnagh/disks/default.nix for the
              # unattended alternative.
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
        swap = {
          # Matches optiplex rather than bearnagh's zram: this is a desktop
          # with a spinning archive disk attached, not a laptop trying to
          # spare an ageing SSD. Roughly the 12.3 GB Debian ran with, rounded
          # up to RAM size.
          size = "16G";
          content = {
            type = "swap";
            discardPolicy = "both";
          };
        };

        root = {
          # No separate data LV, unlike optiplex. Bulk storage on this machine
          # is the 2 TB disk, so root simply takes what is left.
          size = "100%FREE";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
