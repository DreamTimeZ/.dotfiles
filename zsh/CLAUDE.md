# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Plugin Management
- `sheldon lock --update` - Update plugin lockfile after adding/removing plugins in `sheldon/plugins.toml`
- `sheldon source` - Generate and source plugin configuration manually
- `sheldon add <name> --github <repo>` - Add a new plugin from GitHub
- `sheldon remove <name>` - Remove a plugin from configuration
- `exec zsh` - Reload shell after configuration changes

### Development Workflow
- `source ~/.zshrc` - Reload configuration without restarting shell
- `zdotfiles_info "message"` - Log info messages (respects ZDOTFILES_LOG_LEVEL)
- `zdotfiles_warn "message"` - Log warning messages 
- `zdotfiles_error "message"` - Log error messages

### Function Testing
- `which <function_name>` - Check if a function is loaded
- `type <function_name>` - Show function definition and source file
- Source individual module files for testing: `source config/modules/functions/XX-name.zsh`

## Architecture

### Configuration Loading Order
The `.zshrc` loads configuration files in this specific order:
1. `helpers.zsh` - Core helper functions and logging
2. `exports.zsh` - Environment variables and shell options
3. `plugins.zsh` - Sheldon plugin initialization
4. `modules.zsh` - Modular function loader
5. `keybindings.zsh` - Custom key bindings (after plugins)
6. `aliases.zsh` - Command aliases

### Plugin Management System
- **Sheldon** is used for plugin management with `sheldon/plugins.toml` as the main configuration
- Plugins are organized with load order dependencies (powerlevel10k first, syntax highlighting last)
- Custom plugin configurations are in individual `.zsh` files in `sheldon/` directory
- Local plugin files use lazy-loading patterns for version managers (nvm, pyenv, asdf)

### Modular Function System
Functions are organized in `config/modules/functions/` with numerical prefixes:
- `00-core.zsh` - Core utilities (notify, retry, mkdirp, confirm)
- `10-navigation.zsh` - Directory navigation (mkcd, z shortcuts)
- `15-network.zsh` - Network utilities (ip-local, sniff, nscan)
- `20-git.zsh` - Git workflow automation (fbr, fgf - fuzzy git functions)
- `30-process.zsh` - Process management (fp, fh - fuzzy process tools)
- `40-python.zsh` - Python environment management (venv, pcheck)
- `50-webserver.zsh` - Development servers (serve function)
- `60-system.zsh` - System utilities (update_all for macOS)
- `70-services.zsh` - Service management (ollama-* AI tools)
- `80-colorization.zsh` - Generic colorization setup (grc)

### Local Overrides System
- `config/modules/local/` directory for machine-specific customizations
- Local files are loaded last and can override any defaults
- Use `config/modules/local/README.md` as template guide
- Never commit sensitive or machine-specific configurations

### Environment Variables
Key configuration variables:
- `ZDOTFILES_DIR` - Base dotfiles directory (default: `$HOME/.dotfiles`)
- `ZDOTFILES_CONFIG_DIR` - Config directory path
- `ZDOTFILES_MODULES_DIR` - Modules directory path  
- `ZDOTFILES_LOG_LEVEL` - Logging verbosity (0=silent, 1=error, 2=warn, 3=info)

### Smart Defaults and Tool Integration
- `cd` is replaced with zoxide for frecency-based navigation
- `ls` is replaced with eza for enhanced output with colors/icons
- Modern tools have escape hatches (`oldcd`, `oldls`) for fallback
- History configuration optimized for large history files with deduplication
- Completion system uses custom cache location for performance

## Development Workflow

### Adding New Functions
1. Choose appropriate module file in `config/modules/functions/` based on domain
2. Use established logging functions (`zdotfiles_info`, `zdotfiles_warn`, `zdotfiles_error`)
3. Follow existing error handling patterns with early returns
4. Add usage messages for functions that accept parameters
5. Test function loading with `source` and verify with `which`/`type`

### Plugin Integration
1. Add plugin to `sheldon/plugins.toml` with proper load order consideration
2. Create custom configuration file in `sheldon/` if needed (lazy-loading pattern)
3. Run `sheldon lock --update` to update lockfile
4. Test with `exec zsh` to reload shell completely

### Local Customization
1. Create files in `config/modules/local/` for machine-specific overrides
2. Use same numerical prefix system as main functions for load order
3. Override specific functions or add new ones without modifying core files
4. Reference `config/modules/local/README.md` for common patterns

### Function Naming Conventions
- Internal functions: prefix with `zdotfiles_` (e.g., `zdotfiles_has_command`)
- User-facing functions: descriptive names without prefix (e.g., `mkcd`, `serve`)
- Helper functions: descriptive names explaining purpose (e.g., `use_interactive_file_ops`)

## Key Design Principles

- **Performance**: Lazy-loading for version managers and heavy tools
- **Modularity**: Functions organized by domain, easily discoverable
- **Override-friendly**: Local customizations don't require core modifications  
- **Logging**: Structured logging system with configurable verbosity
- **Error Handling**: Defensive programming with usage messages and early returns
- **Namespace Safety**: Internal functions prefixed to avoid conflicts