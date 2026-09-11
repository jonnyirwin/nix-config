"""Emit XDG desktop entries as JSON for Launcher.qml — the drun replacement.

Kept as a standalone script (rather than inline QML/JS) so app listing can
be tested and fixed without touching the shell: `quickshell-list-apps | jq`.
"""
import configparser
import glob
import json
import os
import re
import sys

FIELD_CODE_RE = re.compile(r"%[fFuUdDnNickvm%]")
SIZE_PREF = [
    "scalable", "512x512", "256x256", "128x128", "64x64", "48x48", "32x32",
]


def data_dirs():
    xdg = os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share")
    home_default = os.path.expanduser("~/.local/share")
    home = os.environ.get("XDG_DATA_HOME", home_default)
    dirs = [home] + xdg.split(":")
    seen = []
    for d in dirs:
        if d and d not in seen:
            seen.append(d)
    return seen


def clean_exec(exec_line):
    return FIELD_CODE_RE.sub("", exec_line).strip()


_icon_dirs_cache = None


def icon_search_dirs():
    global _icon_dirs_cache
    if _icon_dirs_cache is not None:
        return _icon_dirs_cache
    dirs = []
    for base in data_dirs():
        icons_base = os.path.join(base, "icons")
        if os.path.isdir(icons_base):
            try:
                for theme in sorted(os.listdir(icons_base)):
                    theme_dir = os.path.join(icons_base, theme)
                    if os.path.isdir(theme_dir):
                        dirs.append(theme_dir)
            except OSError:
                pass
        pixmaps = os.path.join(base, "pixmaps")
        if os.path.isdir(pixmaps):
            dirs.append(pixmaps)
    _icon_dirs_cache = dirs
    return dirs


def resolve_icon(name):
    if not name:
        return ""
    if os.path.isabs(name) and os.path.isfile(name):
        return "file://" + name
    for d in icon_search_dirs():
        for size in SIZE_PREF:
            for ext in ("svg", "png"):
                path = os.path.join(d, size, "apps", f"{name}.{ext}")
                if os.path.isfile(path):
                    return "file://" + path
        for ext in ("png", "svg", "xpm"):
            path = os.path.join(d, f"{name}.{ext}")
            if os.path.isfile(path):
                return "file://" + path
    return ""


def collect():
    entries = {}
    for base in data_dirs():
        apps_dir = os.path.join(base, "applications")
        if not os.path.isdir(apps_dir):
            continue
        pattern = os.path.join(apps_dir, "*.desktop")
        for path in sorted(glob.glob(pattern)):
            cp = configparser.RawConfigParser(
                interpolation=None, strict=False,
            )
            cp.optionxform = str  # desktop-entry keys are case-sensitive
            try:
                cp.read(path, encoding="utf-8")
            except (configparser.Error, UnicodeDecodeError, OSError):
                continue
            if "Desktop Entry" not in cp:
                continue
            section = cp["Desktop Entry"]
            if section.get("NoDisplay", "false").lower() == "true":
                continue
            if section.get("Hidden", "false").lower() == "true":
                continue
            if section.get("Type", "Application") != "Application":
                continue
            name = section.get("Name", "")
            exec_line = section.get("Exec", "")
            if not name or not exec_line:
                continue
            if name in entries:
                continue  # earlier XDG_DATA_DIRS entries win
            entries[name] = {
                "name": name,
                "exec": clean_exec(exec_line),
                "icon": resolve_icon(section.get("Icon", "")),
                "comment": section.get("Comment", ""),
            }
    return sorted(entries.values(), key=lambda e: e["name"].lower())


if __name__ == "__main__":
    json.dump(collect(), sys.stdout)
