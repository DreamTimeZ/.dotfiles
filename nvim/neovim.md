# Neovim Configuration

## Overview

This configuration provides a modern Neovim setup with Lua-based configuration and lazy plugin management.

## Features

- **Modern Lua-based Configuration**: Organized and efficient configuration structure
- **Lazy Plugin Management**: On-demand loading for better performance
- **Advanced Editing Features**:
  - Treesitter syntax highlighting
  - Telescope fuzzy finder
  - Built-in file explorer
  - Git integration
  - Status line
  - System clipboard integration

## Installation

```bash
# Neovim
mkdir -p ~/.config/nvim
ln -sf ~/.dotfiles/nvim/init.lua ~/.config/nvim/init.lua
```

## Requirements

- Neovim >= 0.8.0
- Git (for plugin management)
