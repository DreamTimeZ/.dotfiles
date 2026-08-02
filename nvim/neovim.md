# Neovim Configuration

## Overview

This configuration provides a modern Neovim setup with Lua-based configuration and lazy plugin management.

## Features

- **Modern Lua-based Configuration**: Organized and efficient configuration structure
- **Plugin Management**: lazy.nvim with a committed lockfile. nvim-treesitter loads eagerly, as upstream does not support lazy-loading
- **Advanced Editing Features**:
  - Treesitter syntax highlighting (Neovim-native, skipped above 100 KB)
  - Telescope fuzzy finder
  - File explorer (nvim-tree)
  - Git integration
  - Status line
  - System clipboard integration

## Installation

```bash
# Neovim
mkdir -p ~/.config/nvim
ln -sf ~/.dotfiles/nvim/init.lua ~/.config/nvim/init.lua
ln -sf ~/.dotfiles/nvim/lazy-lock.json ~/.config/nvim/lazy-lock.json
```

## Requirements

- Neovim >= 0.12.0 (nvim-treesitter `main` supports stable and nightly only)
- Git (for plugin management)
- `tree-sitter-cli` >= 0.26.1, from a package manager rather than npm (`brew install tree-sitter-cli`)
- A C compiler, plus `curl` and `tar`, for building parsers

## Notes

netrw is disabled, since nvim-tree replaces it and hijacking it at runtime races with netrw's own load. This removes `:Explore` and netrw's remote-editing handlers (`scp://`, `ftp://`). `gx` is unaffected, as Neovim implements it natively.
