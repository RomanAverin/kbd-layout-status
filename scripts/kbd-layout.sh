#!/usr/bin/env bash
#
# kbd-layout.sh — detect current keyboard layout
#
# Part of kbd-layout-status tmux plugin.
# Called via tmux status-line interpolation: #(/path/to/kbd-layout.sh)
#
# The script automatically detects the environment (Wayland/X11/TTY)
# and calls the appropriate function. To add support for a new
# environment — add a get_layout_<name> function and a condition
# in detect_environment().
#

set -uo pipefail

# ─── Layout detection functions per environment ──────────────────

# GNOME on Wayland (Mutter) — Fedora, Ubuntu, etc.
get_layout_gnome_wayland() {
  # mru-sources contains the current layout as the first element (Most Recently Used)
  local layout
  layout=$(gsettings get org.gnome.desktop.input-sources mru-sources 2>/dev/null |
    grep -oP "'[^']+'" | sed -n '2p' | tr -d "'")

  # Fallback: if mru-sources is empty (initial GNOME state),
  # take the first element from sources
  if [[ -z "$layout" ]]; then
    layout=$(gsettings get org.gnome.desktop.input-sources sources 2>/dev/null |
      grep -oP "'[^']+'" | sed -n '2p' | tr -d "'")
  fi

  echo "$layout"
}

# KDE Plasma on Wayland
# Requires: qdbus or gdbus
get_layout_kde_wayland() {
  qdbus org.kde.keyboard /Layouts org.kde.KeyboardLayouts.getCurrentLayout 2>/dev/null ||
    gdbus call --session \
      --dest org.kde.keyboard \
      --object-path /Layouts \
      --method org.kde.KeyboardLayouts.getCurrentLayout 2>/dev/null |
    tr -d "()'\" "
}

# Sway (wlroots)
# Requires: swaymsg, jq
get_layout_sway() {
  swaymsg -t get_inputs 2>/dev/null |
    jq -r '[.[] | select(.type=="keyboard")][0].xkb_active_layout_name' |
    head -c 2 # first 2 characters, e.g. "Russian" → "Ru"
}

# Hyprland (wlroots)
# Requires: hyprctl, jq
get_layout_hyprland() {
  hyprctl devices -j 2>/dev/null |
    jq -r '.keyboards[0].active_keymap' |
    head -c 2
}

# X11 (any DE) — via xkb-switch or xkblayout-state
get_layout_x11() {
  if command -v xkb-switch &>/dev/null; then
    xkb-switch
  elif command -v xkblayout-state &>/dev/null; then
    xkblayout-state print "%s"
  else
    setxkbmap -query 2>/dev/null | awk '/layout/{print $2}' | cut -d',' -f1
  fi
}

# macOS
get_layout_macos() {
  defaults read ~/Library/Preferences/com.apple.HIToolbox.plist \
    AppleSelectedInputSources 2>/dev/null |
    grep -oP '(?<="KeyboardLayout Name" = ")[^"]+' | head -1
}

# ─── Environment detection ───────────────────────────────────────

detect_environment() {
  # macOS
  if [[ "$(uname)" == "Darwin" ]]; then
    echo "macos"
    return
  fi

  # Wayland
  if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    if [[ -n "${SWAYSOCK:-}" ]]; then
      echo "sway"
    elif [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
      echo "hyprland"
    elif [[ "${XDG_CURRENT_DESKTOP:-}" == *"GNOME"* ]] ||
      [[ "${DESKTOP_SESSION:-}" == *"gnome"* ]]; then
      echo "gnome_wayland"
    elif [[ "${XDG_CURRENT_DESKTOP:-}" == *"KDE"* ]]; then
      echo "kde_wayland"
    else
      # Try GNOME as a fallback for Wayland
      echo "gnome_wayland"
    fi
    return
  fi

  # X11
  if [[ -n "${DISPLAY:-}" ]]; then
    echo "x11"
    return
  fi

  echo "unknown"
}

# ─── Main logic ──────────────────────────────────────────────────

main() {
  local env
  env=$(detect_environment)

  local layout=""

  case "$env" in
  gnome_wayland) layout=$(get_layout_gnome_wayland 2>/dev/null) ;;
  kde_wayland) layout=$(get_layout_kde_wayland 2>/dev/null) ;;
  sway) layout=$(get_layout_sway 2>/dev/null) ;;
  hyprland) layout=$(get_layout_hyprland 2>/dev/null) ;;
  x11) layout=$(get_layout_x11 2>/dev/null) ;;
  macos) layout=$(get_layout_macos 2>/dev/null) ;;
  *) layout="?" ;;
  esac

  # Output the result (fallback to "?" if empty)
  echo "${layout:-?}"
}

main
