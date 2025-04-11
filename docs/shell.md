# Shell Configuration (Zsh)

- [zsh README](../zsh/README.md)

## Overview

The shell configuration uses Zsh with a modern, modular approach:

- Powerlevel10k prompt with instant startup
- Smart directory navigation with `zoxide`
- Sheldon plugin manager for fast, modern plugin management
- Enhanced shell experience with syntax highlighting, auto-suggestions, and fuzzy finding

## Features

- **Modular Configuration**:
  - Exports and environment variables
  - Plugin management
  - Aliases
  - Functions
  - Extra configurations

- **Enhanced Shell Experience**:
  - Syntax highlighting
  - Auto-suggestions and autocompletion
  - Fuzzy finding with `fzf`

- **iTerm2 Integration** with optimized settings (see [iTerm2 Configuration](iterm2.md))

## Installation

```bash
# Zsh
ln -sf ~/.dotfiles/zsh/.zshrc ~/.zshrc
ln -sf ~/.dotfiles/zsh/.zprofile ~/.zprofile

# Sheldon (Zsh plugin manager)
mkdir -p ~/.config/sheldon
ln -sf ~/.dotfiles/zsh/sheldon/plugins.toml ~/.config/sheldon/plugins.toml
sheldon lock --update

# iTerm2 shell integration (optional)
curl -L https://iterm2.com/shell_integration/zsh -o ~/.iterm2_shell_integration.zsh
```

## Security

For improved security, restrict write permissions on function path directories:

```bash
# Restrict write permissions on Zsh function path directory
chmod go-w "$(dirname ${fpath[1]})"

# Restrict write permissions on the cache directory
chmod go-w "${XDG_CACHE_HOME:-$HOME/.cache}"
```

## Requirements

- Zsh
- Sheldon (Zsh plugin manager, installed via Homebrew)
- [Optional] Powerlevel10k
- Additional tools:
  - `zoxide` for smart directory jumping
  - `zsh-syntax-highlighting` for command syntax highlighting
  - `zsh-autosuggestions` for Fish-like autosuggestions
  - `fzf` for fuzzy finding
