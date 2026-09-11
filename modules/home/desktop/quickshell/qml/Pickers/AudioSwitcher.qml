import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.Widgets

// Replaces scripts.nix's audio-switch (wpctl piped into rofi -dmenu). Reads
// straight off Pipewire.nodes rather than parsing `wpctl status` text.
PickerWindow {
    id: root

    namespaceSuffix: "audio-switcher"
    title: "Audio Output"
    searchEnabled: false
    panelWidth: 420
    panelHeight: 280

    IpcHandler {
        target: "audioSwitcher"
        function open() { root.open(); }
        function close() { root.close(); }
        function toggle() { root.toggle(); }
    }

    onAboutToOpen: {
        root.items = Pipewire.nodes.values
            .filter(n => n.audio && n.isSink && !n.isStream)
            .map(n => ({
                "key": n.name,
                "label": n.description || n.nickname || n.name,
                "sublabel": n === Pipewire.defaultAudioSink ? "Active" : "",
                "icon": n === Pipewire.defaultAudioSink ? "󰓃" : "󰓄"
            }));
    }

    onActivated: (item) => {
        const node = Pipewire.nodes.values.find(n => n.name === item.key);
        if (node)
            Pipewire.preferredDefaultAudioSink = node;
    }
}
