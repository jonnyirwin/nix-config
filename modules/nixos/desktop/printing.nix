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

    # The printer on the home LAN. Avahi discovery would eventually produce a queue
    # for it on its own, but a discovered queue is transient and its name is
    # whatever the device advertises; declaring it pins both, and gives the
    # print dialog something already selected rather than an empty list.
    #
    # model = "everywhere" is not a placeholder — it is IPP Everywhere, i.e.
    # "ask the device what it can do". The ENVY 4520 advertises image/urf and
    # image/pwg-raster, so it is fully driverless and needs no HP package.
    #
    # The device URI is the router's DNS name, not an address and not mDNS, and
    # both halves of that are deliberate:
    #
    #   - Not the IP. DHCP can hand the printer a different lease, and a
    #     hardcoded address fails silently when it does.
    #   - Not `.local`, and not the `dnssd://` URI that `lpinfo -v` prints.
    #     Both look like the right answer and neither survives setup: this CUPS
    #     is built against Avahi rather than Bonjour, and on that build the
    #     `.local` branch of libcups' address resolution never falls through to
    #     getaddrinfo. `lpadmin -m everywhere` has to contact the device to read
    #     its capabilities, so it fails with "Name or service not known" even
    #     though `getent hosts` resolves the same name fine — and the dnssd URI
    #     fails identically, because it resolves *to* the .local name.
    #
    # model = "everywhere" is IPP Everywhere: "ask the device what it can do".
    # The ENVY 4520 advertises image/urf and image/pwg-raster, so it is fully
    # driverless and needs no HP driver package.
    #
    # `ensure-printers.service` applies this at boot, and fails harmlessly if
    # the printer is switched off or the laptop is away from home. Losing it is not fatal either way — Avahi
    # discovery still produces a working queue on its own, just an
    # auto-named one; this block is what pins the name and the default.
    hardware.printers = {
      ensureDefaultPrinter = "envy4520";
      ensurePrinters = [{
        name = "envy4520";
        description = "HP ENVY 4520";
        location = "home";
        deviceUri = "ipp://HPB8559D.lan:631/ipp/print";
        model = "everywhere";
      }];
    };

    # cups-browsed would find the same printer over mDNS and write a *second,
    # permanent* queue for it into printers.conf, pointing at an implicitclass://
    # URI. The declared queue above already covers this device, so that is just
    # a stale artifact to keep in step — and deleting it by hand does not stick,
    # it is rewritten the next time cups-browsed starts.
    #
    # This does NOT collapse the print dialog to one entry, and it is not meant
    # to. libcups enumerates DNS-SD printers client-side, so as long as Avahi is
    # running the ENVY also appears as a transient
    # `HP_ENVY_4520_series_B8559D` (ipps://…:443) that lives nowhere on disk.
    # Both entries reach the same hardware and `envy4520` is the pinned default,
    # so the twin is cosmetic; the only way to remove it is to stop running
    # Avahi, which would cost the scanner its discovery. Deliberately not doing
    # that — see modules/nixos/desktop/avahi.nix.
    #
    # Turn this back on when printing somewhere with printers this config does
    # not declare.
    services.printing.browsed.enable = false;
  };
}
