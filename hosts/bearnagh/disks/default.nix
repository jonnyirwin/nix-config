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
