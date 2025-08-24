# ZSH Configuration System

A clean, modular ZSH configuration with modern tools and smart defaults.

## 🚀 Quick Start

```bash
# macOS with Homebrew
brew install zsh git sheldon fzf zoxide eza ripgrep

# Clone and link
git clone <your-repo> ~/.dotfiles
ln -sf ~/.dotfiles/zsh/.zshrc ~/.zshrc
ln -sf ~/.dotfiles/zsh/.zprofile ~/.zprofile

# Reload shell
exec zsh
```

## ✨ Key Features

- **🎯 Smart Defaults**: `cd` uses zoxide, `ls` uses eza by default
- **🔧 Modular Design**: Functions organized in logical modules  
- **⚡ Fast Startup**: Optimized loading with lazy initialization
- **🛡️ Non-Breaking**: Modern tools with escape hatches (`oldcd`, `oldls`)
- **📦 Rich Functions**: 50+ productivity functions included

## 📁 Structure

```text
zsh/
├── config/
│   ├── aliases.zsh           # Clean aliases only
│   ├── atuin/                # Shell history configuration
│   │   └── config.toml       # Auto-symlinked to ~/.config/atuin/
│   ├── exports.zsh           # Environment & options
│   ├── modules/
│   │   ├── functions/        # Organized by domain
│   │   │   ├── 10-navigation.zsh  # mkcd, dusage, ffind
│   │   │   ├── 15-network.zsh     # ip-local, sniff, nscan  
│   │   │   ├── 20-git.zsh         # fbr, fgf (fuzzy git)
│   │   │   ├── 30-process.zsh     # fp, fh (process mgmt)
│   │   │   ├── 40-python.zsh      # venv, pcheck (quality)
│   │   │   ├── 50-webserver.zsh   # serve (dev server)
│   │   │   ├── 60-system.zsh      # update_all (macOS)
│   │   │   ├── 70-services.zsh    # ollama-* (AI tools)
│   │   │   └── 80-colorization.zsh # grc setup
│   │   └── local/            # Your customizations
│   └── plugins.zsh           # Plugin management
├── sheldon/                  # Plugin configs
└── docs/                     # Documentation
```

## 🎮 Highlights

### Smart Navigation

- `cd` → zoxide (frecency-based, learns your patterns)
- `mkcd dir` → create and enter directory
- `z proj` → jump to ~/Projects
- `zi` → interactive directory picker

### Enhanced Listing

- `ls` → eza (colors, icons, git status)
- `ll` → detailed view with icons
- `tree` → directory tree view

### Developer Tools

- `ip-local` → network interface overview
- `serve` → instant dev server (Node.js/Python)
- `venv` → smart Python environment manager
- `pcheck` → comprehensive code quality check

### Shell History (Atuin)

- Enhanced shell history with sync capabilities
- Fuzzy search and workspace filtering
- Configuration auto-managed in `config/atuin/`

## 🔧 Customization

Create `~/.dotfiles/zsh/config/modules/local/personal.zsh`:

```zsh
# Enable interactive file operations
use_interactive_file_ops

# Add custom aliases
alias work='cd ~/Projects'
alias config='cd ~/.dotfiles'

# Machine-specific paths
export PATH="$HOME/custom-tools:$PATH"
```

## 📚 Documentation

- [Structure](docs/structure.md) - Complete directory layout
- [Features](docs/features.md) - All available functions
- [Usage](docs/usage.md) - Customization guide
- [Keybindings](docs/keybindings.md) - Keyboard shortcuts
