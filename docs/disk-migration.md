# Moving the OS from the SATA SSD to the NVMe

## Why this is less dangerous than it sounds

The OS disk holds almost nothing irreplaceable:

| Path | Size | Matters? |
|---|---|---|
| `/nix` | 37 G | No — rebuilds from this flake |
| `/home` | 1.3 G | Yes, but small |
| `/var` | 160 M | Logs, mostly disposable |

The irreplaceable data is the 113 G on `/mnt/data`, which lives on the **NVMe**
— the disk being repartitioned. So the whole plan is arranged around never
having that data in only one place for longer than necessary.

## Current vs target

```
NOW                                  TARGET
sda   238 G SATA                     sda   238 G SATA
  p1    1 G  /boot                     p1  238 G  /mnt/storage  (ext4, bulk)
  p2  225 G  LUKS → ext4  /
  p3   12 G  LUKS → swap            nvme  477 G
                                       p1    1 G  /boot         (ESP)
nvme  477 G                            p2  476 G  LUKS "cryptroot"
  p1  477 G  ext4  /mnt/data                └─ LVM "pool"
                                                ├─ root  200 G  /
                                                ├─ swap   16 G
                                                └─ data  rest   /mnt/data
```

Two improvements fall out of the change: one passphrase at boot instead of a
separate LUKS container for swap, and LVM underneath so root/data can be
resized later without repartitioning.

## Before starting

**Back up the irreplaceable subset to something outside this machine.** There
is no external drive attached, so the plan below uses the SATA disk as the
staging area. That is genuinely safe for a disk *wipe*, but it is not a backup
— during Phase 2 the only copy of your data is on a single 11-year-old SATA
SSD. At minimum get these off the machine first:

```
/mnt/data/jonny/Camera            20 G
/mnt/data/jonny/git               11 G   (clonable if pushed)
/mnt/data/jonny/obsidian-backup   192 M
/mnt/data/jonny/Second-Brain_old  193 M
```

`RetroPie` (43 G) and `pi-backup` (1.7 G) are presumably re-obtainable.

## Phase 1 — Stage the data onto the SATA disk

Nothing destructive. Afterwards the data exists twice, on two physical disks.

```bash
sudo mkdir -p /var/migration
sudo rsync -aHAX --info=progress2 /mnt/data/ /var/migration/data/

# Verify before trusting it
sudo diff -rq /mnt/data /var/migration/data && echo "identical"
df -h /          # expect ~152 G used of 221 G
```

## Phase 2 — Provision the NVMe

**Destructive to the NVMe only.** This is the single-copy window: from here
until Phase 4 completes, your data exists only in `/var/migration` on the SATA
disk. The SATA disk is not touched by any command in this phase.

Temporarily drop `./ssd.nix` from `hosts/optiplex/disks/default.nix` so the
installer does not expect a partition that does not exist yet.

```bash
sudo umount /mnt/data

# Formats ONLY the NVMe — ssd.nix is a separate file and is not referenced here
sudo nix run github:nix-community/disko -- \
  --mode destroy,format,mount \
  ./hosts/optiplex/disks/nvme.nix

# Target is now mounted at /mnt. Install into it.
sudo nixos-install --flake .#optiplex --no-root-passwd

# Carry the small stateful bits across
sudo rsync -aHAX /home/jonny/ /mnt/home/jonny/
```

You will be asked to set the LUKS passphrase during `disko`.

## Phase 3 — Boot from the NVMe

Reboot and pick the NVMe in the firmware boot menu (F12 on this OptiPlex).
Both disks now carry an ESP, so make the NVMe first in the boot order once
you have confirmed it works.

Do **not** wipe anything yet. If the NVMe install is wrong, the old system on
the SATA disk still boots and still has `/var/migration`.

## Phase 4 — Restore the data

```bash
# Unlock and mount the old root
sudo cryptsetup open /dev/disk/by-uuid/335c42eb-1da8-43f2-a271-5caa94b81c57 oldroot
sudo mkdir -p /mnt/old && sudo mount /dev/mapper/oldroot /mnt/old

sudo rsync -aHAX --info=progress2 /mnt/old/var/migration/data/ /mnt/data/
sudo diff -rq /mnt/old/var/migration/data /mnt/data && echo "identical"
```

Two copies again. Stop here for a few days if you want to be sure.

## Phase 5 — Reclaim the SATA disk

**Destructive to the SATA disk**, and it destroys the old OS and the staging
copy. Only run it once Phase 4 has been verified.

```bash
sudo umount /mnt/old
sudo cryptsetup close oldroot

sudo nix run github:nix-community/disko -- \
  --mode destroy,format \
  ./hosts/optiplex/disks/ssd.nix
```

Restore the `./ssd.nix` import, then `nrs`.

## Phase 6 — Retire the old hand-written config

Once booted from the NVMe, disko owns every filesystem and facter owns the
hardware, so the generated file and the hand-carried disk facts go away:

- delete `hosts/optiplex/hardware.nix` and its import
- delete `fileSystems."/mnt/data"` from `hosts/optiplex/default.nix`
- delete the `boot.initrd.luks.devices."luks-3f374acb-…"` swap entry — the new
  swap is an LV inside `cryptroot` and needs no separate unlock

Confirm nothing was lost:

```bash
nixos-rebuild build --flake .#optiplex
nvd diff /run/current-system ./result
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT
```

## Provisioning a *new* machine

The same two files are what make a fresh install trivial — no manual
partitioning at all:

```bash
# from the NixOS installer, with this flake checked out
sudo nix run github:nix-community/disko -- \
  --mode destroy,format,mount ./hosts/<name>/disks
sudo nixos-install --flake .#<name>

# then, on the new machine, capture its hardware
sudo nix run nixpkgs#nixos-facter -- -o hosts/<name>/facter.json
```
