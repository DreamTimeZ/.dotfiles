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
- **🛡️ Non-Breaking**: Modern tools with graceful fallbacks
- **📦 Rich Utilities**: Productivity functions and aliases included

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
│   │   │   ├── 00-core.zsh        # notify, retry, confirm
│   │   │   ├── 05-clipboard.zsh   # cross-platform clipboard
│   │   │   ├── 10-navigation.zsh  # mkcd, dusage, ffind
│   │   │   ├── 15-network.zsh     # ip-local, sniff, nscan
│   │   │   ├── 16-websearch.zsh   # google, ghs, yt, so
│   │   │   ├── 20-git.zsh         # fbr, fgf (fuzzy git)
│   │   │   ├── 30-process.zsh     # fpkill, fh (process mgmt)
│   │   │   ├── 40-python.zsh      # venv (environment mgmt)
│   │   │   ├── 45-tmux.zsh        # dev (tmux sessions)
│   │   │   ├── 50-webserver.zsh   # serve (dev server)
│   │   │   ├── 60-system.zsh      # update (system updater)
│   │   │   ├── 65-introspection.zsh # zh (config picker)
│   │   │   ├── 70-services.zsh    # ollama-* (AI tools)
│   │   │   ├── 75-knowledge.zsh   # yt2note, ytt, ytc
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
- `dirty` → scan git repos for uncommitted changes
- `zh` → browse/search dotfiles aliases, functions, exports, keybindings

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
