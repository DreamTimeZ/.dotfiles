# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Zsh Development
- `sheldon lock --update` - Update plugin lockfile after adding/removing plugins in `sheldon/plugins.toml`
- `sheldon source` - Generate and source plugin configuration
- `sheldon add <name> --github <repo>` - Add a new plugin
- `sheldon remove <name>` - Remove a plugin

### Configuration Management
- `exec zsh` - Reload shell configuration after changes
- `source ~/.zshrc` - Reload configuration without restarting shell
- `ln -sf ~/.dotfiles/zsh/.zshrc ~/.zshrc` - Link zsh configuration

### Tool Configuration
- `config/atuin/config.toml` - Atuin shell history configuration (auto-symlinked to `~/.config/atuin/`)

## Architecture

### Modular Configuration System
The ZSH configuration uses a highly modular, convention-based architecture:

- **Entry point**: `.zshrc` loads configuration in strict order: helpers → exports → plugins → modules → keybindings → aliases
- **Helper system** (`config/helpers.zsh`): Core utilities with logging (`zdotfiles_info`, `zdotfiles_warn`, `zdotfiles_error`), path management, command detection, and lazy loading
- **Plugin management**: Sheldon-based with declarative configuration in `sheldon/plugins.toml` and lazy-loaded tool integrations

### Function Modules (`config/modules/functions/`)
Organized by numerical prefix for load order:
- `00-core.zsh` - Core utilities (notify, retry, confirm)
- `10-navigation.zsh` - Directory navigation helpers
- `15-network.zsh` - Network utilities
- `20-git.zsh` - Git workflow functions (fbr, fgf for fuzzy git operations)
- `30-process.zsh` - Process management utilities
- `40-python.zsh` - Python environment management
- `50-webserver.zsh` - Development server helpers
- `60-system.zsh` - System administration tools
- `70-services.zsh` - Service management utilities
- `80-colorization.zsh` - Color enhancement setup

### Local Override System
- **Local configurations** (`config/modules/local/`): Machine-specific overrides that load last and won't be committed
- **Template system**: `example.zsh.template` provides examples for common customizations
- **Namespace protection**: All internal functions prefixed with `zdotfiles_` to avoid conflicts

### Plugin Architecture
- **Lazy loading**: Version managers (nvm, pyenv, asdf) and tools (direnv, zoxide) initialize only when needed
- **Load order dependencies**: Critical plugins (powerlevel10k) load first, syntax highlighters load last
- **Custom configurations**: Tool-specific config files in `sheldon/` directory (fzf-tab-config.zsh, etc.)
- **Auto-configuration**: Tools like atuin automatically setup configuration symlinks on first load

### Logging and Performance
- **Configurable logging**: `ZDOTFILES_LOG_LEVEL` controls verbosity (0=silent, 1=error, 2=warn, 3=info)
- **Startup optimization**: Silent mode during instant prompt, command caching, optimized loading order
- **Path management**: Duplicate-free path manipulation with existence validation

## Key Design Principles

- **Convention over configuration**: Numerical prefixes determine load order, consistent naming patterns
- **Fail-safe defaults**: Graceful degradation when tools unavailable, fallback configurations
- **Local customization**: Override system prevents conflicts with shared configuration
- **Performance-first**: Lazy loading, caching, minimal startup overhead
- **Namespace isolation**: Prefixed functions prevent conflicts with user code

## Development Workflow

### Adding New Functionality
1. Place functions in appropriate numbered module file in `config/modules/functions/`
2. Use established logging system for user feedback
3. Check command availability with `zdotfiles_has_command` before using tools
4. Follow error handling patterns from existing modules

### Plugin Management
1. Add plugin to `sheldon/plugins.toml` with appropriate load order
2. Run `sheldon lock --update` to update lockfile
3. Create custom config file in `sheldon/` if needed
4. Use lazy loading for performance-sensitive tools

### Local Development
- Use `config/modules/local/*.zsh` for machine-specific configurations
- Override functions and settings without modifying core files
- Test changes with `exec zsh` to reload configuration