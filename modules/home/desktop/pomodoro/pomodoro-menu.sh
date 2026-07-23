#!/usr/bin/env bash

# Pomodoro control menu using rofi.
#
# The "Configure Times" and sound-toggle entries are gone: they worked by
# sed-ing pomodoro.conf in place, which is now generated from Nix
# (jonny.desktop.pomodoro.*) and lives read-only in the store.

CONFIG_FILE="${POMODORO_CONF:?POMODORO_CONF must be set by the Nix wrapper}"

# shellcheck source=/dev/null
source "$CONFIG_FILE"

choice=$(printf '%s\n' \
    "🍅 Start Work (${WORK_TIME_MINUTES}min)" \
    "☕ Short Break (${SHORT_BREAK_MINUTES}min)" \
    "☕ Long Break (${LONG_BREAK_MINUTES}min)" \
    "⏸️ Toggle Pause/Resume" \
    "⏹️ Stop Timer" \
    "🔄 Skip to Work Session" \
    | rofi -dmenu -i -p "Pomodoro Timer")

case "$choice" in
    "🍅 Start Work"*)          pomodoro start ;;
    "☕ Short Break"*)         pomodoro short-break ;;
    "☕ Long Break"*)          pomodoro long-break ;;
    "⏸️ Toggle Pause/Resume")  pomodoro toggle ;;
    "⏹️ Stop Timer")           pomodoro stop ;;
    "🔄 Skip to Work Session") pomodoro skip-break ;;
    *) exit 0 ;;
esac
