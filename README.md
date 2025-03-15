# .dotfiles

Modern, modular dotfiles configuration for a productive macOS development environment.

## 🎯 Overview

A carefully curated collection of dotfiles optimized for:
- 🔧 Zsh with Powerlevel10k
- 📝 Neovim with lazy.nvim
- 📦 Tmux with plugin management
- 🔑 SSH with local overrides
- 🌳 Git with split configuration

## ✨ Features

### Shell (Zsh)

- Powerlevel10k prompt with instant startup
- Smart directory navigation with `zoxide`
- Enhanced shell experience:
  - Syntax highlighting
  - Auto-suggestions and autocompletion
  - Fuzzy finding with `fzf`
- Modular configuration with separate files for:
  - Exports and environment variables
  - Plugin management
  - Aliases
  - Functions
  - Extra configurations

### Neovim

- Modern Lua-based configuration
- Lazy plugin management
- Features include:
  - Treesitter syntax highlighting
  - Telescope fuzzy finder
  - Built-in file explorer
  - Git integration
  - Status line
  - System clipboard integration

### Tmux

- Custom prefix key (Ctrl+A)
- Vim-style pane navigation
- Mouse support
- Clipboard integration
- Session management
- Plugins:
  - tmux-resurrect
  - tmux-continuum
  - tmux-cpu
  - tmux-yank
  - tmux-open

## 🚀 Installation

### COMING SOON! Automatic Setup (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/DreamTimeZ/dotfiles-macos/main/install.sh | bash
```

Or clone and run the installer:

```bash
git clone git@github.com:DreamTimeZ/dotfiles-macos.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

### Manual Setup

1. Clone the repository:
```bash
git clone git@github.com:DreamTimeZ/dotfiles-macos.git ~/.dotfiles
```

2. Create symbolic links:
```bash
# Zsh
ln -sf ~/.dotfiles/zsh/.zshrc ~/.zshrc
ln -sf ~/.dotfiles/zsh/.zprofile ~/.zprofile

# Neovim
mkdir -p ~/.config/nvim
ln -sf ~/.dotfiles/nvim/init.lua ~/.config/nvim/init.lua

# Tmux
ln -sf ~/.dotfiles/tmux/.tmux.conf ~/.tmux.conf

# Git
ln -sf ~/.dotfiles/git/.gitconfig ~/.gitconfig
ln -sf ~/.dotfiles/git/.gitignore_global ~/.gitignore_global

# SSH
ln -sf ~/.dotfiles/ssh/config ~/.ssh/config
```

## 📋 Requirements

- macOS
- Git
- Zsh
- Neovim >= 0.8.0
- Tmux >= 3.0
- [Optional] Powerlevel10k
- [Optional] Tmuxinator for session management
- Additional tools:
  - `zoxide` for smart directory jumping
  - `zsh-syntax-highlighting` for command syntax highlighting
  - `zsh-autosuggestions` for Fish-like autosuggestions
  - `fzf` for fuzzy finding

## 🔧 Local Customization

The configuration supports local overrides through `.local` files:
- `git/.gitconfig.local`: Git user info and machine-specific settings
- `ssh/config.local`: Machine-specific SSH configurations

## 🗺️ Roadmap

### Planned Features

- [ ] Automated installation script / Configuration wizard for first-time setup
- [ ] Package manager integration (Homebrew)
- [ ] Backup and restore system for configurations
- [ ] Performance optimization and startup time improvements

## 📝 License

MIT License
