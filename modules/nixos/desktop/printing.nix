{ lib, pkgs, config, ... }:

let
  cfg = config.jonny.desktop;
in
{
  options.jonny.desktop.printing.enable =
    lib.mkEnableOption "printing (CUPS, driverless IPP, mDNS printer discovery)";

  config = lib.mkIf (cfg.enable && cfg.printing.enable) {
    # Without cupsd running there is no print *system* at all, only the
    # toolkit's built-in "Print to File" — which is why an unconfigured
    # desktop looks like it can only save PDFs. GTK, Qt and Firefox all reach
    # printers exclusively through CUPS, so this one line is the difference
    # between a PDF exporter and a print dialog.
    services.printing = {
      # Socket-activated by default (services.printing.startWhenNeeded), so
      # cupsd is not a resident daemon: the first application to open the
      # print dialog starts it, and it exits again when idle.
      enable = true;

      # Deliberately no `drivers = [ ... ]`. Modern network printers speak
      # IPP Everywhere / AirPrint, which means they publish their own
      # capabilities and accept a standard raster format — CUPS generates the
      # queue from the device itself and no vendor PPD is involved. Add a
      # driver package here only for hardware that predates that (and for HP
      # specifically, `pkgs.hplip` is the one to reach for; the closure is
      # large, so it is not worth carrying speculatively).
      #
      # Also deliberately not `browsing = true`: that shares *our* queues out
      # to the network, which is a different thing from finding other
      # people's, and this machine has no printer to share.
    };

    # mDNS discovery lives in ./avahi.nix — scanning needs the same daemon, so
    # neither module owns it.

    # cupsd's own web UI on localhost:631 can do everything this can, but it
    # wants an admin password over a form; system-config-printer authenticates
    # through polkit instead, which is the nicer path for adding a printer
    # that discovery did not find.
    environment.systemPackages = [ pkgs.system-config-printer ];

    # Note on permissions: CUPS admin is granted to the `lpadmin` group, and
    # NixOS's cupsd config additionally lists root and `wheel` as SystemGroup.
    # jonny is already in `wheel` (modules/nixos/core/users.nix), so there is
    # no group to add here — printing itself needs no membership at all.
  };
}
