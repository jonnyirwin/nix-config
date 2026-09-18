# Target layout for the sole disk in this machine.
#
# Toshiba THNSNH256GBST, 256 GB SATA. Referenced by stable by-id path — never
# /dev/sda, which is allocation-order dependent.
#
# Shape: ESP + a single LUKS container holding an LVM volume group. Encrypted
# because it is a laptop, and the rest of the fleet is encrypted.
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

              # No passwordFile, deliberately. disko's `askPassword` therefore
              # defaults to true and `cryptsetup luksFormat` prompts, which
              # works under nixos-anywhere: it allocates a pty whenever its own
              # stdin is a terminal (sshTtyParam="-t"), so the prompt reaches
              # you. The passphrase then exists only in your head and in the
              # LUKS header — never in a file, this repo, or a shell history.
              #
              # The alternative, `passwordFile`, is only worth reaching for if
              # this ever needs to run unattended. Note the file's contents
              # become the real passphrase, so prefer feeding it from a
              # password manager over writing plaintext to disk:
              #   nixos-anywhere --disk-encryption-keys /tmp/disk.key <(pass ...)
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
          # real swap device at least as large as memory. It is an LV inside
          # the LUKS container, so the hibernation image is encrypted too.
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
