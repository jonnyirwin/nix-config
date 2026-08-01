# Target layout for the sole disk in this machine.
#
# Toshiba THNSNH256GBST, 256 GB SATA. Referenced by stable by-id path — never
# /dev/sda, which is allocation-order dependent.
#
# Shape: ESP + a single LUKS container holding an LVM volume group. The disk
# is unencrypted under EndeavourOS today; this encrypts it, which is the one
# deliberate departure from "replicate what works". It is a laptop, and the
# rest of the fleet is encrypted.
#
# Unlike bearnagh there IS a swap LV, because this machine hibernates — see
# boot.resumeDevice in ../default.nix.
{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/disk/by-id/ata-TOSHIBA_THNSNH256GBST_632S102ATE8Y";

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

              # Read once, by `cryptsetup luksFormat`, at install time only.
              # Without it disko's `askPassword` defaults to true and the
              # format step stops for an interactive prompt, which is awkward
              # in the middle of an unattended nixos-anywhere run.
              #
              # The file's contents ARE the real passphrase — this sets the
              # one you will type at every boot, not a throwaway install
              # token. Only the path lives here, so no secret enters the repo;
              # create it at install time and delete it afterwards:
              #   (umask 077; printf '%s' 'the-passphrase' > /tmp/disk.key)
              #   nixos-anywhere --disk-encryption-keys /tmp/disk.key /tmp/disk.key ...
              #   shred -u /tmp/disk.key
              # A trailing newline is stripped, so `echo` works too; leading
              # and internal spaces are kept.
              passwordFile = "/tmp/disk.key";
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
          # 18 GB against 16 GB of RAM. Sized for hibernation, which needs a
          # real swap device at least as large as memory — the machine runs
          # with `resume=` set today and this keeps that working. The old
          # layout used a bare 17.1 GB partition; here it is an LV inside the
          # LUKS container, so the hibernation image is encrypted too, which
          # it previously was not.
          size = "18G";
          content = {
            type = "swap";
            discardPolicy = "both";
          };
        };

        root = {
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
