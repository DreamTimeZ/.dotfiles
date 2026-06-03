# .dotfiles

Modern, modular dotfiles configuration for productive development environments on macOS, Linux, and Windows (WSL).

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
- ⌨️ Karabiner for keyboard remapping (macOS)
- 📝 Espanso for text expansion (macOS, Linux, Windows)
- 🖥️ Cross-platform support for macOS, Linux, and Windows (WSL)

## ✨ Key Features

- **Modern Shell**:
  - Modular Zsh configuration with isolated components
  - Powerlevel10k for a beautiful, informative prompt
  - Syntax highlighting, auto-suggestions, and Atuin shell history
  - FZF integration for fuzzy file finding and history search
  - Sheldon for fast, declarative plugin management

- **Development Environment**:
  - Neovim with Lua configuration and lazy loading plugins
  - Tmux with sensible defaults and session management
  - Git with public/private configuration separation
  - Platform-specific optimizations

- **System Management**:
  - Hammerspoon for keyboard shortcuts and window management (macOS)
  - LaunchAgents for service automation (macOS)
  - Karabiner for keyboard remapping (macOS)
  - Espanso for text expansion (macOS, Linux, Windows)
  - SSH key management with platform detection

- **Customization**:
  - Local overrides for machine-specific settings
  - Private repository integration for sensitive configurations
  - Support for platform-specific configurations
  - Documented customization points

## 🚀 Installation

### Quick Install

```bash
git clone https://github.com/username/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./setup.sh --all
```

Or install selectively (`core`, `cli`, `dev`, `extra`, `macos`):

```bash
./setup.sh core cli dev
```

Run `./setup.sh --doctor` to verify your setup.

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
- Recommended tools: fzf, eza, zoxide

#### Linux

- Required packages: zsh, git, curl, fzf
- Installation method varies by distribution (see [Installation Guide](docs/installation.md))

#### Windows (WSL)

- Windows Subsystem for Linux
- Ubuntu or Debian WSL distribution
- Windows Terminal (recommended)

## 🧹 Linting

Pre-commit hooks keep the repo clean (config: `.pre-commit-config.yaml`). Install once with `pre-commit install`, lint everything with `pre-commit run --all-files`, and update hook versions with `pre-commit autoupdate`.

- **Hygiene**: trailing whitespace, end-of-file, YAML/JSON syntax, merge- and case-conflict guards, large-file and private-key detection.
- **Markdown** (`markdownlint-cli2`): rules in `.markdownlint.jsonc`. `CLAUDE*.md` and `zsh/config/prompts/*.md` are excluded (context files and AI prompt payloads, not docs).
- **Shell**: `shellcheck` for bash (`setup.sh` and the bash scripts in `bin/`). Shellcheck cannot parse zsh, so `.zsh` files get a `zsh -n` syntax check instead.

`pre-commit` is the only extra prerequisite; the hook repos provide shellcheck, markdownlint, and node.

## 🗺️ Roadmap

- Backup and restore system
- Enhanced Linux and WSL compatibility

## 📝 License

MIT License
