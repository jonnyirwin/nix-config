# nix

Jonny's NixOS + Home Manager configuration.

One flake builds every machine. Shared behaviour lives in `modules/`, and a
host under `hosts/` is only the things that are genuinely specific to it —
hardware facts and a handful of toggles.

## Layout

```
flake.nix          inputs, host discovery, dev shells, lint checks
lib/
  mkHost.nix       builds one nixosConfiguration from a hosts/ directory
  schemes/         colour schemes — catppuccin, gruvbox-dark, nord
hosts/<name>/
  default.nix      NixOS config: hardware, platform, jonny.* toggles
  facter.json      hardware report, from nixos-facter
  disks/           disko layout; also derives fileSystems and swap
  home.nix         optional per-host Home Manager overrides
modules/nixos/     system config — core/ always on, desktop/ gated
modules/home/      user config — core, shell, terminal, editor, desktop
devshells/         per-language dev environments
docs/              longer-form notes
```

Everything user-facing is under one option namespace, `jonny.*`, so a host
reads as a list of decisions rather than a pile of NixOS internals.

## Rebuilding

Shell aliases (defined in `modules/home/shell/aliases.nix`) target *this*
host automatically:

| alias    | what it does                                                 |
| -------- | ------------------------------------------------------------ |
| `nrs`    | `nixos-rebuild switch` — build and activate now               |
| `nrt`    | `nixos-rebuild test` — activate without touching the bootloader |
| `nrb`    | build only, then `nvd diff` against the running system        |
| `nrboot` | stage as the next boot's default, without activating live     |

Use `nrboot` and reboot for anything that touches the display manager or the
initrd. Applying a display-manager change with a live `switch` restarts the
greeter out from under the running session.

Run `nrb` first when you want to see what a change actually costs — it prints a
package-level diff rather than a wall of store paths.

## Adding a machine

`flake.nix` discovers hosts by reading `hosts/`, so a new directory becomes a
`nixosConfiguration` with no edit to the flake. The architecture comes from the
host's own `nixpkgs.hostPlatform`, so an aarch64 machine needs no special case.

1. `mkdir hosts/<name>`
2. Generate the hardware report:
   `sudo nix run nixpkgs#nixos-facter -- -o hosts/<name>/facter.json`
3. Write `hosts/<name>/disks/` — see `hosts/optiplex/disks/` for an encrypted
   LUKS + LVM layout, and `docs/disk-migration.md` for applying one.
4. Write `hosts/<name>/default.nix`: imports, `nixpkgs.hostPlatform`,
   `system.stateVersion`, boot loader, and the `jonny.*` toggles you want.
5. Optionally add `hosts/<name>/home.nix` for per-host user config — displays,
   backup paths.
6. If the host needs secrets, add it to `.sops.yaml` (instructions are in that
   file) and create `secrets/<name>.yaml`.

Then `nixos-rebuild switch --flake .#<name>`.

### Headless hosts

Leave `jonny.desktop.enable` unset. Everything graphical — compositor, bar,
launcher, portals, audio, the terminal emulator, the PDF viewer — is gated on
it, so a server gets the shell, the TUI tools and the editor without pulling a
display stack into its profile.

## Theming

A host declares its scheme once, in `hosts/<name>/default.nix`:

```nix
jonny.theme = {
  scheme = "catppuccin-mocha";  # or gruvbox-dark, nord, catppuccin-{latte,frappe,macchiato}
  accent = "purple";
};
```

SDDM reads that directly, and the Home Manager side defaults from it via
`osConfig`, so the greeter and the session cannot drift apart. Set
`jonny.theme` inside `home.nix` only if you deliberately want them to differ.

Accents are named by hue rather than by a scheme's own vocabulary, so `purple`
means Catppuccin's mauve, Gruvbox's bright purple and Nord's nord15 — switching
scheme keeps your accent choice meaningful.

Adding a scheme is a file in `lib/schemes/` plus a line in its `default.nix`;
every module renders from the resolved palette, so nothing else changes.

## Dev environments

Per-language shells, replacing mise and ghcup:

```sh
nix develop ~/git/nix#ruby              # one-off
echo "use flake ~/git/nix#ruby" > .envrc && direnv allow   # per project
```

Available: `haskell`, `elixir`, `rust`, `ruby`. A project with its own flake
should use that instead.

## Checks

```sh
nix flake check
```

Evaluates every host and runs `statix`, `deadnix` and a `nixpkgs-fmt`
formatting check over the tree. CI runs the same command on every push
(`.github/workflows/check.yml`), so a dead binding, an unformatted file or a
host that no longer evaluates fails there rather than at rebuild time.

Format with `nix fmt`.
