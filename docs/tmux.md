# Tmux Configuration

## Overview

This Tmux configuration provides a productive terminal multiplexer setup with plugin management and enhanced usability.

## Features

- **Custom Prefix Key**: Ctrl+A for easier access
- **Vim-Style Navigation**: Familiar keybindings for pane navigation
- **Mouse Support**: Click to select panes, resize, and scroll
- **Clipboard Integration**: Seamless copying between Tmux and system
- **Session Management**: Save and restore sessions
- **Enhanced Plugins**:
  - tmux-resurrect: Session saving and restoration
  - tmux-continuum: Automatic session saving
  - tmux-cpu: System resource monitoring
  - tmux-yank: Improved clipboard handling
  - tmux-open: Open highlighted text in applications

## Installation

```bash
# Tmux
ln -sf ~/.dotfiles/tmux/.tmux.conf ~/.tmux.conf
```

## Requirements

- Tmux >= 3.0
- [Optional] Tmuxinator for session management 