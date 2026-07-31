{ lib, pkgs, config, ... }:

let
  cfg = config.jonny.desktop;
in
{
  options.jonny.desktop.scanning.enable =
    lib.mkEnableOption "scanning (SANE, driverless eSCL over the network)";

  config = lib.mkIf (cfg.enable && cfg.scanning.enable) {
    hardware.sane = {
      enable = true;

      # eSCL / AirScan — the scanning half of what makes a modern all-in-one
      # driverless. The scanner is an HTTP service on the device (the ENVY
      # 4520 advertises _uscan._tcp on port 8080) that returns JPEG or PDF, so
      # there is no vendor backend involved and nothing to keep working across
      # a SANE bump.
      #
      # This is why there is no `pkgs.hplipWithPlugin` here. That is the
      # traditional answer for an HP all-in-one and it would work, but it
      # means a large closure and a binary blob to do what the device already
      # exposes over standard HTTP.
      extraBackends = [ pkgs.sane-airscan ];

      # Deliberately not `openFirewall`. Despite the name it opens UDP 8612,
      # which is Canon's BJNP discovery protocol and nothing to do with eSCL —
      # airscan finds devices over mDNS, which Avahi already covers.
    };

    # No `scanner`/`lp` group membership needed. Those exist so that a *USB*
    # scanner's device node is readable by a normal user; a network scanner
    # has no device node, and airscan just talks HTTP to the printer's
    # address. Add jonny to `scanner` only if a USB scanner ever appears.

    # All of these find the sane-airscan device with no configuration, and
    # `scanimage -L` from the CLI sees the same one.
    #
    # The spread is deliberate rather than indecisive: the ENVY 4520 is a
    # platen with no document feeder (it advertises `is=platen`, `duplex=F`),
    # so every page is a manual lift-the-lid operation and the thing that
    # actually makes scanning bearable is assembling multi-page output without
    # reconfiguring per sheet. That is the axis these differ on.
    environment.systemPackages = with pkgs; [
      # Saved profiles, scan-more-pages into one document, page reorder before
      # saving, OCR and auto-deskew built in. The everyday driver.
      naps2

      # Heavier post-processing than NAPS2 — unpaper cleanup, deskew, per-page
      # editing — behind an older GTK UI. Worth reaching for on poor-quality
      # originals, not for routine scans.
      gscan2pdf

      # Adds a searchable text layer to an already-scanned PDF, which is the
      # one job neither GUI does well from the command line. tesseract is the
      # engine it drives; listed explicitly so the CLI is on PATH in its own
      # right, not just as ocrmypdf's private dependency.
      ocrmypdf
      tesseract

      # Kept alongside the above for one-off "just scan this" runs, where
      # NAPS2's profile-first model is more ceremony than the job needs.
      simple-scan
    ];
  };
}
