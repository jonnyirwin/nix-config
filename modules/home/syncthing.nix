{ config, lib, osConfig ? { }, ... }:

# Peer-to-peer file sync; web UI on http://localhost:8384.
#
# Devices and folders are declared once here, for every machine, and each host
# works out its own slice from its hostname: it gets the folders that list it,
# and the peers it shares those folders with. With override* on, anything added
# through the web UI is dropped on the next activation — edit this file instead.
#
# Keys are not managed here. Each host generates its own cert/key under
# ~/.local/state/syncthing on first start; a device ID is only the fingerprint
# of that cert, so committing it is fine. Read a new host's with
# `syncthing device-id` and add it to `devices`.
#
# Sync runs over Tailscale only (see the options below), so a device's key in
# `devices` must also be its tailnet hostname, and the host needs
# jonny.services.tailscale.enable, which opens 22000 on tailscale0.
#
# Conflicts: when two machines edit the same file between syncs, the newer
# mtime wins and the loser is kept beside it as
# <name>.sync-conflict-<date>-<time>-<device>.<ext>. Nothing is lost, but
# nothing announces it either; `fd sync-conflict ~/git/hutton` to look.
let
  cfg = config.jonny.syncthing;

  devices = {
    optiplex = "JFRT5M5-S5LUQAW-KBP6ZUF-4ZZUTLW-GOXIYIO-MX5KNTA-4F3WLAI-FSD2QQS";
    bearnagh = "ZU6CZAZ-RMB4TBV-5GP2OAC-LOJDDCC-KAZJXCY-CPJ6JAD-5KMZBUN-POZMQAN";
  };

  folders = {
    hutton = {
      path = "~/git/hutton";
      devices = [ "optiplex" "bearnagh" ];
    };
  };

  mine = lib.filterAttrs (_: f: lib.elem cfg.host f.devices) folders;
  peers = lib.remove cfg.host (lib.unique (lib.concatMap (f: f.devices) (lib.attrValues mine)));
in
{
  options.jonny.syncthing.host = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = osConfig.networking.hostName or null;
    defaultText = lib.literalExpression "osConfig.networking.hostName";
    description = "This machine's key in the device table above.";
  };

  config.services.syncthing = {
    enable = true;
    overrideDevices = true;
    overrideFolders = true;

    settings = {
      # Peers are dialled by their tailnet (MagicDNS) name and nothing else.
      devices = lib.genAttrs peers (name: {
        id = devices.${name};
        addresses = [ "tcp://${name}:22000" ];
      });

      folders = lib.mapAttrs (_: f: {
        inherit (f) path;
        devices = lib.remove cfg.host f.devices;
        # Replaced and deleted files go to .stversions/ rather than vanishing,
        # thinned out over time and dropped after 30 days.
        versioning = {
          type = "staggered";
          params.maxAge = toString (30 * 24 * 3600);
        };
      }) mine;

      options = {
        urAccepted = -1; # no usage reporting, and no prompt asking about it
        # Tailnet only: no announcing to Syncthing's public discovery servers
        # or the LAN, and no public relays. This is what makes the committed
        # device IDs above harmless — there is nothing to look them up in.
        globalAnnounceEnabled = false;
        localAnnounceEnabled = false;
        relaysEnabled = false;
        natEnabled = false;
      };
    };
  };
}
