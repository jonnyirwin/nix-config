pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Replaces mako: claims org.freedesktop.Notifications directly rather than
// shelling to a second daemon. `history` mirrors mako's max-history +
// `makoctl restore` — see restoreLast() and the notificationReplay keybinding
// in sway.nix.
Singleton {
    id: root

    property bool doNotDisturb: false
    property ListModel toasts: ListModel {}
    property var history: []
    readonly property int historyLimit: 20

    readonly property NotificationServer server: NotificationServer {
        keepOnReload: true
        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notif => root._handle(notif)
    }

    function _urgencyName(u) {
        switch (u) {
        case NotificationUrgency.Critical:
            return "critical";
        case NotificationUrgency.Low:
            return "low";
        default:
            return "normal";
        }
    }

    function _handle(notif) {
        // Retainable: without this the object is freed once the sender's
        // D-Bus call returns, before we've had a chance to render it.
        notif.tracked = true;

        const entry = {
            "summary": notif.summary || "",
            "body": notif.body || "",
            "appName": notif.appName || "App",
            "appIcon": notif.appIcon || "",
            "image": notif.image || "",
            "urgency": root._urgencyName(notif.urgency),
            "timeoutMs": notif.expireTimeout > 0 ? notif.expireTimeout : 6000,
            "time": Date.now(),
            "ref": notif
        };

        root._remember(entry);

        if (root.doNotDisturb && entry.urgency !== "critical") {
            try {
                notif.dismiss();
            } catch (e) {
                // already gone
            }
            return;
        }

        root.toasts.append(entry);
    }

    function _remember(entry) {
        const trimmed = {
            "summary": entry.summary,
            "body": entry.body,
            "appName": entry.appName,
            "appIcon": entry.appIcon,
            "urgency": entry.urgency,
            "time": entry.time
        };
        let next = root.history.concat([trimmed]);
        if (next.length > root.historyLimit)
            next = next.slice(next.length - root.historyLimit);
        root.history = next;
    }

    function dismiss(index) {
        if (index < 0 || index >= root.toasts.count)
            return;
        const entry = root.toasts.get(index);
        try {
            if (entry.ref)
                entry.ref.dismiss();
        } catch (e) {
            // sender already withdrew it
        }
        root.toasts.remove(index);
    }

    function dismissAll() {
        while (root.toasts.count > 0)
            root.dismiss(0);
    }

    function invoke(index, actionId) {
        if (index < 0 || index >= root.toasts.count)
            return;
        const entry = root.toasts.get(index);
        try {
            const actions = entry.ref ? entry.ref.actions : [];
            for (let i = 0; i < actions.length; i++) {
                if (actions[i].identifier === actionId) {
                    actions[i].invoke();
                    break;
                }
            }
        } catch (e) {
            // action API drifted from what this was written against
        }
        root.dismiss(index);
    }

    // The "what did that say?" recovery bound to notificationReplay — the
    // same job makoctl restore did. count > 1 walks further back through
    // history rather than replaying the same most-recent entry repeatedly
    // (the command-menu's "Replay last ten").
    function restoreLast(count) {
        const n = Math.min(count || 1, root.history.length);
        for (let i = 0; i < n; i++) {
            const last = root.history[root.history.length - 1 - i];
            root.toasts.append({
                "summary": last.summary,
                "body": last.body,
                "appName": last.appName,
                "appIcon": last.appIcon,
                "image": "",
                "urgency": last.urgency,
                "timeoutMs": 6000,
                "time": Date.now(),
                "ref": null
            });
        }
    }
}
