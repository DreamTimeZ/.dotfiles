# Tmux Cheatsheet

Quick reference for custom tmux bindings. Prefix: `Ctrl+a`

## GENERAL

| Shortcut | Description |
|----------|-------------|
| `Ctrl+a` | Prefix key (replaces default `Ctrl+b`) |
| `prefix` `r` | Reload tmux config |
| `prefix` `?` | Show all keybindings (built-in) |

## PANES

| Shortcut | Description |
|----------|-------------|
| `prefix` `=` | Split horizontally (side by side) |
| `prefix` `-` | Split vertically (stacked) |
| `prefix` `h/j/k/l` | Navigate panes (vim-style) |
| `prefix` `H/J/K/L` | Resize panes (repeatable) |
| `prefix` `<` | Rename pane |
| `prefix` `x` | Kill pane |
| `prefix` `S` | Toggle pane synchronization |

## WINDOWS

| Shortcut | Description |
|----------|-------------|
| `prefix` `c` | New window (in current directory) |
| `prefix` `Ctrl+h` | Previous window (repeatable) |
| `prefix` `Ctrl+l` | Next window (repeatable) |
| `prefix` `Tab` | Last window |
| `prefix` `&` | Kill window |

## COPY MODE (Vi-style)

> **Note:** Copy mode = the mode itself (scroll, search, select, copy). Vi-mode = the keybinding style within copy mode.

| Shortcut | Description |
|----------|-------------|
| `prefix` `Enter` | Enter copy mode |
| `v` | Begin selection |
| `Ctrl+v` | Rectangle selection toggle |
| `y` | Copy to system clipboard |
| `Escape` | Cancel and exit |

### Navigation in Copy Mode

| Key | Description |
|-----|-------------|
| `h/j/k/l` | Move left/down/up/right |
| `w` / `b` | Word forward/backward |
| `0` / `$` | Start/end of line |
| `g` / `G` | Top/bottom of buffer |
| `Ctrl+u/d` | Page up/down |

### Search in Copy Mode

| Key | Description |
|-----|-------------|
| `/` | Search forward |
| `?` | Search backward |
| `n` / `N` | Next/previous match |

## PLUGINS (TPM)

| Shortcut | Description |
|----------|-------------|
| `prefix` `I` | Install plugins |
| `prefix` `U` | Update plugins |

**Tips:**

- Splits open in current directory (not home)
- Mouse support is enabled for scrolling and selection
- Clipboard auto-detects platform (macOS/WSL/X11/Wayland)
- Sessions auto-save every 10 minutes (tmux-continuum)
