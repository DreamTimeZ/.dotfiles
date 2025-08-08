# ZSH Configuration System

A modular, maintainable, and testable ZSH configuration system designed for efficiency and easy customization.

## Quick Start

```zsh
# macos example with brew
# Core requirements
brew install zsh git sheldon fzf nvm

# Essential tools
brew install zoxide direnv thefuck bat eza glow mas

# Development tools
brew install asdf pyenv poetry nodemon httpie grc

# Optional but useful
brew install ripgrep tldr tmux kubectl ollama docker

# Clone repository
git clone https://github.com/username/dotfiles.git ~/.dotfiles

# Create symlinks
ln -sf ~/.dotfiles/zsh/.zshrc ~/.zshrc
ln -sf ~/.dotfiles/zsh/.zprofile ~/.zprofile
```

For detailed installation instructions, see [Requirements](docs/requirements.md).

## Documentation

- [**Features**](docs/features.md) - Complete feature list
- [**Requirements**](docs/requirements.md) - Installation requirements for all platforms
- [**Structure**](docs/structure.md) - Directory structure and organization
- [**Usage Guide**](docs/usage.md) - How to use and customize
- [**Keybindings**](docs/keybindings.md) - Keyboard shortcuts

## Key Features

- **Modular Design**: Each component is isolated for easier maintenance
- **Cross-Platform**: Works on macOS, Linux, and Windows (WSL)
- **Performance Optimized**: Fast startup time and efficient resource usage
- **Customizable**: Easy to extend with your own configurations

## Directory Overview

```markdown
zsh/
├── config/           - Core configuration files
├── sheldon/          - Plugin management
├── docs/             - Documentation
├── .zshrc            - Main configuration entry point
└── .zprofile         - Login shell configuration
```

See [Structure](docs/structure.md) for a complete layout.

## Customization

See the [Usage Guide](docs/usage.md) for detailed instructions on customizing your configuration.
