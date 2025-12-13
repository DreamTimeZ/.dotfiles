# ZSH Configuration Requirements

This document provides detailed information about the requirements for running the ZSH configuration system across different platforms.

## Core Requirements (All Platforms)

- Zsh 5.8+ (recommended: latest version)
- Git (for cloning and updates)
- [Sheldon](https://github.com/rossmacarthur/sheldon) (plugin manager)
- Python 3.7+ (for various shell functions)
- curl or wget (for installation script)
- fzf (fuzzy finder, used by various functions)

## Platform-Specific Requirements

### macOS

```zsh
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install required packages
brew install zsh git sheldon fzf eza python3 mas terminal-notifier

# Optional but recommended tools
brew install zoxide thefuck direnv glow
```

### Linux (Debian/Ubuntu)

```bash
# Update package lists
sudo apt-get update

# Install required packages
sudo apt-get install -y zsh git python3 python3-pip curl fzf

# Install sheldon
curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh \
  | bash -s -- --repo rossmacarthur/sheldon --to ~/.local/bin

# Install recommended tools
sudo apt-get install -y eza direnv
pip3 install thefuck

# Make zsh your default shell
chsh -s $(which zsh)
```

### Windows (WSL)

```bash
# Update package lists
sudo apt-get update

# Install required packages
sudo apt-get install -y zsh git python3 python3-pip curl

# Install sheldon
curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh \
  | bash -s -- --repo rossmacarthur/sheldon --to ~/.local/bin

# Install fzf
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

# Make zsh your default shell
chsh -s $(which zsh)
```

## Optional Dependencies

- **direnv**: For directory-specific environment variables
- **zoxide**: Smart directory navigation (alternative to `cd`)
- **thefuck**: Command correction utility
- **eza/exa**: Modern replacement for `ls`
- **glow**: Markdown terminal viewer
- **pyenv**: Python version manager
- **Powerlevel10k**: ZSH theme (installed automatically via Sheldon)
