# Tmux Cheatsheet

Quick reference for tmux bindings. Prefix: `Ctrl+a`

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
| `prefix` `<` | Set pane name (protected, overrides program titles) |
| `prefix` `>` | Clear pane name (show program title again) |
| `prefix` `z` | Toggle pane zoom (fullscreen) |
| `prefix` `x` | Kill pane (no confirmation) |
| `prefix` `S` | Toggle pane synchronization |

## WINDOWS

| Shortcut | Description |
|----------|-------------|
| `prefix` `c` | New window (in current directory) |
| `prefix` `Ctrl+h` | Previous window (repeatable) |
| `prefix` `Ctrl+l` | Next window (repeatable) |
| `prefix` `Tab` | Last window |
| `prefix` `&` | Kill window (no confirmation) |

## POPUP SHELLS

| Shortcut | Description |
|----------|-------------|
| `prefix` `g` | Quick popup shell (70% × 70%) |
| `prefix` `G` | Large popup shell (80% × 80%) |

Popups open in the current pane's directory and close on `exit`. They have no scrollback or copy mode, so use tools that scroll themselves (lazygit, htop, less).

## COPY MODE (Vi-style)

| Shortcut | Description |
|----------|-------------|
| `prefix` `Enter` | Enter copy mode |
| `prefix` `]` | Paste buffer (bracketed) |
| `v` | Begin selection |
| `Ctrl+v` | Rectangle selection toggle |
| `y` | Copy to system clipboard (raw, preserves all whitespace) |
| `Shift+y` | Copy clean: strips Claude Code's 2-space padding, joins soft-wrapped lines, converts tables to Markdown (`tmux/scripts/clean-copy.pl --help`) |
| `Escape` | Cancel and exit |

### Navigation in Copy Mode

| Key | Description |
|-----|-------------|
| `h/j/k/l` | Move left/down/up/right |
| `w` / `b` | Word forward/backward |
| `0` / `$` | Start/end of line |
| `g` / `G` | Top/bottom of buffer |
| `Ctrl+u/d` | Half page up/down |
| `Ctrl+b/f` | Page up/down |

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

## NOTES

- Splits and new windows open in the current directory
- Mouse support is enabled for scrolling and selection
- Clipboard auto-detects platform (macOS/WSL/X11/Wayland)
- Plugins: tmux-resurrect, tmux-continuum (auto-save every 10 minutes), tmux-prefix-highlight, tmux-open
- The tmux server outlives the terminal, `tmux kill-server` for a full reset
