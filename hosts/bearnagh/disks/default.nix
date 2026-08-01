# Target layout for the sole disk in this machine.
#
# Kingston SV300S37A240G, 240 GB SATA. Referenced by stable by-id path — never
# /dev/sda, which is allocation-order dependent.
#
# Unlike optiplex there is only one disk, so this is a single file rather than
# a directory of them: there is no second device to format independently, and
# nothing to stage data onto during a migration. Everything the machine has
# lives inside the LUKS container.
#
# Shape: ESP + a single LUKS container holding an LVM volume group. One
# passphrase at boot, and LVM underneath so /home or a swap LV can be carved
# out later without repartitioning.
{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/disk/by-id/ata-KINGSTON_SV300S37A240G_50026B72470287BD";

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
        # One volume taking the whole group. The LVM layer is still worth
        # having on a single-LV disk: it is what makes "actually, /home should
        # be separate" or "this does need a swap LV after all" a resize rather
        # than a reinstall.
        #
        # There is deliberately no swap LV — see zramSwap in ../default.nix.
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
