# .dotfiles macOS

Modern, modular dotfiles configuration for a productive macOS development environment with cross-platform compatibility.

## 🎯 Overview

A carefully curated collection of dotfiles optimized for:

- 🔧 Zsh with modular configuration and Powerlevel10k
- 🔌 Plugin management with Sheldon (modern alternative to oh-my-zsh)
- 📝 Neovim with lazy.nvim for efficient plugin management
- 📦 Tmux with sensible defaults and plugin management
- 🔑 SSH with local overrides for machine-specific settings
- 🌳 Git with split configuration for public/private settings
- 🔨 Hammerspoon for macOS automation and window management
- 🚀 LaunchAgents for macOS system service management
- 🖥️ Cross-platform support (primarily macOS, with Linux and WSL compatibility)

## ✨ Key Features

- **Modern Shell**:
  - Modular Zsh configuration with isolated components
  - Powerlevel10k for a beautiful, informative prompt
  - Syntax highlighting, auto-suggestions, and history substring search
  - FZF integration for fuzzy file finding and history search
  - Sheldon for fast, declarative plugin management

- **Development Environment**:
  - Neovim with Lua configuration and lazy loading plugins
  - Tmux with sensible defaults and session management
  - Git with public/private configuration separation
  - Platform-specific optimizations

- **System Management**:
  - Hammerspoon for keyboard shortcuts and window management
  - LaunchAgents for service automation
  - SSH key management with platform detection

- **Customization**:
  - Local overrides for machine-specific settings
  - Support for platform-specific configurations
  - Documented customization points

## 🚀 Installation

### Quick Install (manual until automated script is ready)

```bash
# Clone the repository
git clone https://github.com/username/dotfiles.git ~/.dotfiles

# Navigate to the directory
cd ~/.dotfiles

# Set up components you need (examples)
ln -sf ~/.dotfiles/zsh/.zshrc ~/.zshrc
ln -sf ~/.dotfiles/zsh/.zprofile ~/.zprofile
ln -sf ~/.dotfiles/nvim/init.lua ~/.config/nvim/init.lua
ln -sf ~/.dotfiles/tmux/.tmux.conf ~/.tmux.conf
```

See the [Installation Guide](docs/installation.md) for complete step-by-step instructions.

## 📚 Documentation

For detailed information on each component:

- [Installation Guide](docs/installation.md) - Detailed setup instructions
- [Shell Configuration](docs/shell.md) - Zsh and Sheldon setup
- [Neovim Configuration](nvim/neovim.md) - Editor setup
- [Tmux Configuration](tmux/tmux.md) - Terminal multiplexer setup
- [Hammerspoon Configuration](hammerspoon/README.md) - macOS automation
- [LaunchAgents](launchagents/launchagents.md) - System service management
- [iTerm2 Configuration](docs/iterm2.md) - Terminal emulator setup
- [Repository Structure](docs/structure.md) - Understanding the organization

## 📋 Requirements

### Core Requirements

- Git (for cloning and version control)
- Zsh 5.8+ (default on recent macOS)
- Sheldon (plugin manager for Zsh)

### Platform-Specific Requirements

#### macOS

- Homebrew for package management
- iTerm2 (recommended terminal emulator)
- Recommended tools: fzf, eza/exa, zoxide, thefuck, direnv

#### Linux

- Required packages: zsh, git, curl, fzf
- Installation method varies by distribution (see [Installation Guide](docs/installation.md))

#### Windows (WSL)

- Windows Subsystem for Linux
- Ubuntu or Debian WSL distribution
- Windows Terminal (recommended)

## 🗺️ Roadmap

- Automated installation script with configuration wizard
- Homebrew formula management
- Backup and restore system
- Enhanced Linux and WSL compatibility

## 📝 License

MIT License
