# Tmux Configuration

## Overview

This Tmux configuration provides a productive terminal multiplexer setup with plugin management and enhanced usability.

## Features

- **Custom Prefix Key**: Ctrl+A for easier access
- **Vim-Style Navigation**: Familiar keybindings for pane navigation
- **Mouse Support**: Click to select panes, resize, and scroll
- **Clipboard Integration**: Seamless copying between Tmux and system
- **Session Management**: Save and restore sessions
- **Plugins**:
  - tmux-resurrect: Session saving and restoration
  - tmux-continuum: Automatic session saving
  - tmux-prefix-highlight: Visual prefix indicator
  - tmux-open: Open highlighted text in applications

## Keybindings

| Binding | Action |
|---------|--------|
| `C-a =` | Horizontal split |
| `C-a -` | Vertical split |
| `C-a h/j/k/l` | Pane navigation |
| `C-a H/J/K/L` | Pane resize |
| `C-a C-h/C-l` | Previous/next window |
| `C-a Tab` | Last window |
| `C-a Enter` | Copy mode |
| `C-a r` | Reload config |
| `C-a x` | Kill pane |
| `C-a ?` | List all keybindings |

## Installation

```bash
# Tmux
ln -sf ~/.dotfiles/tmux/.tmux.conf ~/.tmux.conf
```

## Requirements

- Tmux >= 3.0
- [Optional] Tmuxinator for session management
