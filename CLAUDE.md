# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Zsh Development
- `sheldon lock --update` - Update plugin lockfile after adding/removing plugins in `zsh/sheldon/plugins.toml`
- `sheldon source` - Generate and source plugin configuration
- `sheldon add <name> --github <repo>` - Add a new plugin
- `sheldon remove <name>` - Remove a plugin

### Tmux Development
- `tmux source-file ~/.tmux.conf` - Reload tmux configuration
- `<prefix> + I` - Install tmux plugins (TPM)
- `<prefix> + U` - Update tmux plugins
- `<prefix> + r` - Reload config (custom binding)

### Neovim Development
- `:Lazy sync` - Sync plugins with lazy.nvim
- `:Lazy install` - Install missing plugins
- `:Lazy update` - Update plugins
- `:TSUpdate` - Update Treesitter parsers

### Installation and Linking
- `ln -sf ~/.dotfiles/zsh/.zshrc ~/.zshrc` - Link zsh configuration
- `ln -sf ~/.dotfiles/tmux/.tmux.conf ~/.tmux.conf` - Link tmux configuration
- `ln -sf ~/.dotfiles/nvim/init.lua ~/.config/nvim/init.lua` - Link neovim configuration

## Architecture

### Modular Zsh Configuration
The Zsh configuration uses a highly modular architecture:

- **Core files in `zsh/config/`**:
  - `exports.zsh` - Environment variables and shell options
  - `plugins.zsh` - Plugin initialization via Sheldon
  - `modules.zsh` - Loads modular functions from `modules/` directory
  - `keybindings.zsh` - Custom key bindings
  - `aliases.zsh` - Command aliases

- **Plugin management via Sheldon** (`zsh/sheldon/`):
  - `plugins.toml` - Declarative plugin configuration with load order
  - Individual `.zsh` files for tool-specific lazy loading (nvm, pyenv, asdf, etc.)
  - Custom configuration files for complex plugins (fzf-tab-config.zsh)

- **Modular functions** (`zsh/config/modules/functions/`):
  - `00-core.zsh` - Core utilities and logging functions
  - `10-navigation.zsh` - Directory navigation helpers
  - `20-git.zsh` - Git workflow automation
  - `30-process.zsh` - Process management utilities
  - `50-webserver.zsh` - Development server helpers
  - `60-system.zsh` - System administration tools

- **Local overrides** (`zsh/config/modules/local/`):
  - Machine-specific configurations that override defaults
  - Template files for common customizations

### Tmux Plugin System
- Uses TPM (Tmux Plugin Manager) for plugin management
- Plugins stored in `tmux/plugins/tpm/`
- Configuration supports session resurrection and auto-restoration
- Custom key bindings use Ctrl+A prefix instead of default Ctrl+B

### Neovim Lazy Loading
- Uses lazy.nvim for efficient plugin management
- Minimal core configuration with essential plugins
- Treesitter for syntax highlighting with "all" language support
- Telescope for fuzzy finding, NvimTree for file exploration

### Hammerspoon Modular System
- Entry point in `hammerspoon/init.lua`
- Modular hotkey system in `hammerspoon/modules/hotkeys/`
- Configuration system with local overrides in `config/local/`
- Separated concerns: validation, logging, modals, actions, UI

### SSH Configuration
- Split configuration with `ssh/config` for general settings
- `ssh/config.local` for machine-specific overrides
- Designed for easy deployment across multiple machines

## Development Workflow

### Adding New Zsh Functionality
1. Add new functions to appropriate module file in `zsh/config/modules/functions/`
2. Use the established logging system (`zdotfiles_info`, `zdotfiles_warn`, `zdotfiles_error`)
3. Follow the existing code style with proper error handling

### Plugin Management
1. For Zsh: Add to `zsh/sheldon/plugins.toml`, run `sheldon lock --update`
2. For Tmux: Add to `.tmux.conf`, install with `<prefix> + I`
3. For Neovim: Add to `init.lua` lazy.setup table, sync with `:Lazy sync`

### Local Customization
- Use `local/` directories for machine-specific overrides
- Never commit sensitive information or machine-specific paths to the main configuration
- Template files show examples of common customizations

## Key Design Principles

- **Modularity**: Each component can be used independently
- **Lazy Loading**: Tools like NVM, PyEnv only initialize when needed
- **Local Overrides**: Machine-specific settings don't interfere with main config
- **Cross-platform**: Primary macOS focus with Linux/WSL compatibility considerations
- **Performance**: Optimized loading order and lazy initialization for fast shell startup
- **Documentation**: Each major component has its own documentation file