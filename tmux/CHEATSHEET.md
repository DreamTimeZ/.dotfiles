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
| `prefix` `<` | Rename pane |
| `prefix` `z` | Toggle pane zoom (fullscreen) |
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

## POPUP SHELLS

| Shortcut | Description |
|----------|-------------|
| `prefix` `g` | Quick popup shell (70% × 70%) |
| `prefix` `G` | Large popup shell (80% × 80%) |

**Tips:**

- Popups float above your layout without disrupting it
- Dismiss with `Ctrl+D` or `exit` (ephemeral, no state preserved)
- Opens in current pane's directory
- No scrollback/copy mode - use tools with built-in scroll (lazygit, htop, less)
- Quick (`g`): git status, one-liners, quick lookups
- Large (`G`): lazygit, htop, extended work

## COPY MODE (Vi-style)

> **Note:** Copy mode = the mode itself (scroll, search, select, copy). Vi-mode = the keybinding style within copy mode.

| Shortcut | Description |
|----------|-------------|
| `prefix` `Enter` | Enter copy mode |
| `prefix` `]` | Paste buffer (bracketed) |
| `v` | Begin selection |
| `Ctrl+v` | Rectangle selection toggle |
| `y` | Copy to system clipboard (raw, preserves all whitespace) |
| `Shift+y` | Copy clean (for Claude Code output, see below) |
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
- Config changes require reload: `prefix r` or `tmux source-file ~/.tmux.conf`
- Tmux server persists across terminal restarts; use `tmux kill-server` for full reset

### Clean Copy (`Shift+y`) for Claude Code

Cleans Claude Code output: strips 2-space padding, joins soft-wrapped lines, converts tables to markdown — while preserving lists, code blocks, and paragraph breaks.

| Key | Use Case |
|-----|----------|
| `y` | Raw copy — code, logs, exact whitespace |
| `Shift+y` | Clean copy — prose, docs from Claude Code |

Full documentation: `$ZDOTFILES_DIR/tmux/scripts/clean-copy.pl --help`
