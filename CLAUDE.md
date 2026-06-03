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
- `./setup.sh --all` - Install packages and create all symlinks
- `./setup.sh --link-only` - Create symlinks only (no package installs)
- `./setup.sh --unlink` - Remove all managed symlinks
- `./setup.sh --doctor` - Verify the setup
- Symlink mappings live in `symlinks.conf` (grouped: shell, tmux, editor, git, ssh, ...). Edit there; `setup.sh` creates parent dirs and backs up existing files, which manual `ln` does not.

### Linting
- `pre-commit install` - Activate the git pre-commit hook (one-time)
- `pre-commit run --all-files` - Run all lint hooks (markdownlint, shellcheck, zsh -n, hygiene)
- `pre-commit autoupdate` - Bump hook versions
- shellcheck covers bash only; `.zsh` files get `zsh -n` instead (shellcheck cannot parse zsh)

## Architecture

### Modular Zsh Configuration
The Zsh configuration uses a highly modular architecture:

- **Core files in `zsh/config/`**:
  - `exports.zsh` - Environment variables and shell options
  - `helpers.zsh` - PATH helpers and the `zdotfiles_info/warn/error` logging functions
  - `plugins.zsh` - Plugin initialization via Sheldon
  - `modules.zsh` - Loads numerically-prefixed function modules from `modules/functions/`
  - `keybindings.zsh` - Custom key bindings
  - `aliases.zsh` - Command aliases
  - `local.zsh` - Sources machine-specific overrides from `modules/local/`

- **Plugin management via Sheldon** (`zsh/sheldon/`):
  - `plugins.toml` - Declarative plugin configuration with load order
  - Individual `.zsh` files for tool-specific lazy loading (zoxide, etc.)
  - Custom configuration files for complex plugins (fzf-tab-config.zsh)

- **Modular functions** (`zsh/config/modules/functions/`):
  - `NN-*.zsh` files auto-loaded in numeric order by `modules.zsh`. Run `ls zsh/config/modules/functions/` for the current set (e.g. `00-core`, `20-git`, `40-python`, `60-system`, `75-knowledge`).
  - Core utilities are in `00-core.zsh`; the logging functions themselves live in `zsh/config/helpers.zsh`.

- **Local overrides** (`zsh/config/modules/local/`):
  - Machine-specific configurations that override defaults
  - Template files for common customizations

### Tmux Plugin System
- Uses TPM (Tmux Plugin Manager) for plugin management
- TPM installed at `~/.tmux/plugins/tpm/` (standard location)
- Configuration supports session resurrection and auto-restoration
- Custom key bindings use Ctrl+A prefix instead of default Ctrl+B

### Neovim Lazy Loading
- Uses lazy.nvim for efficient plugin management
- Minimal core configuration with essential plugins
- Treesitter for syntax highlighting (curated parser list in init.lua, auto_install fetches others on demand via the tree-sitter CLI)
- Telescope for fuzzy finding, NvimTree for file exploration

### Hammerspoon Modular System
- Entry point in `hammerspoon/init.lua`
- Modular hotkey system in `hammerspoon/modules/hotkeys/`
- Configuration system with local overrides in `modules/hotkeys/config/local/`
- Separated concerns across subdirectories: `core/`, `modals/`, `macros/`, `ui/`, `utils/`

### SSH Configuration
- Split configuration with `ssh/config` for general settings
- `ssh/local/` for machine-specific overrides
- Designed for easy deployment across multiple machines

### Private Repository Integration
- Private repo at `~/.dotfiles-private` maintains sensitive and machine-specific files
- Private repo is the source of truth for all `local/` configuration files
- Files are symlinked from `~/.dotfiles-private` to `~/.dotfiles/*/local/`
- This separation ensures sensitive data never enters the public repository

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
- **Lazy Loading**: Tools initialize on demand via Sheldon; runtime versions are managed by mise (`zsh/sheldon/mise.zsh`)
- **Local Overrides**: Machine-specific settings don't interfere with main config
- **Cross-platform**: Primary macOS focus with Linux/WSL compatibility considerations
- **Performance**: Optimized loading order and lazy initialization for fast shell startup
- **Documentation**: Substantial components ship their own README/docs (zsh/, tmux/, nvim/, hammerspoon/, gpg/), read on demand

## Hammerspoon Hotkeys Logging

### Configuration
The hotkeys logger lives in `hammerspoon/modules/hotkeys/core/logging.lua` with config in `config/config.lua`:

#### **Log Levels (Default: ERROR only)**
- `ERROR (1)`: Critical failures requiring immediate attention
- `WARN (2)`: Warning conditions that should be monitored
- `INFO (3)`: General information (disabled in production)
- `DEBUG (4)`: Detailed debugging (disabled in production)

Public API in `logging.lua`: `setLogLevel`, `setLoggingEnabled`, `getLogStats`. Rate-limited, message-sanitized, and `pcall`-guarded; see the source for internals.

#### **Usage Guidelines**
- Use `ERROR` for critical failures only
- Use `WARN` for recoverable issues that need monitoring
- Avoid `INFO`/`DEBUG` in production code
- Keep log messages concise and actionable
- Include context for complex operations
- Never log sensitive information (passwords, keys, etc.)
