# kbd-layout-status

A tmux plugin that displays the current keyboard layout in the status bar.

Automatically detects the desktop environment and uses the appropriate method to query the active layout.

## Supported Environments

| Environment        | Method                                         |
| ------------------ | ---------------------------------------------- |
| GNOME Wayland      | `ibus` / `gsettings` (fallback)                |
| KDE Plasma Wayland | `qdbus` / `gdbus`                              |
| Sway               | `swaymsg` + `jq`                               |
| Hyprland           | `hyprctl` + `jq`                               |
| X11 (any DE)       | `xkb-switch` / `xkblayout-state` / `setxkbmap` |
| macOS              | `defaults read` (HIToolbox)                    |

## Installation

### With [TPM](https://github.com/tmux-plugins/tpm)

Add the plugin to your `tmux.conf`:

```tmux
set -g @plugin 'romanaverin/kbd-layout-status'
```

Press `prefix + I` to install.

### Manual

```bash
git clone https://github.com/romanaverin/kbd-layout-status ~/.config/tmux/plugins/kbd-layout-status
```

Add to `tmux.conf`:

```tmux
run-shell ~/.config/tmux/plugins/kbd-layout-status/kbd-layout-status.tmux
```

## Usage

Add `#{kbd_layout}` to your `status-right` or `status-left`:

```tmux
set -g status-right "#{kbd_layout}"
```

The placeholder will be replaced with the script call when the plugin loads.
If you have a color scheme and it is in a separate file, then that is where you need to place the configuration.

## Configuration

### `@kbd-layout-format`

Wrap the layout output in a custom format. Use `#{value}` as the placeholder for the layout value:

```tmux
set -g @kbd-layout-format '#[fg=yellow]#{value}#[fg=default]'
```

This produces `#[fg=yellow]<layout>#[fg=default]` in the status bar.

If not set, the raw layout value is displayed.

## Dependencies

The plugin requires tools specific to your environment:

- **GNOME Wayland**: `ibus` (usually pre-installed), `gsettings` (fallback)
- **KDE Wayland**: `qdbus` or `gdbus`
- **Sway**: `swaymsg`, `jq`
- **Hyprland**: `hyprctl`, `jq`
- **X11**: `xkb-switch`, `xkblayout-state`, or `setxkbmap`
- **macOS**: no extra dependencies

## License

[MIT](LICENSE)
