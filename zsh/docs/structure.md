# ZSH Configuration Structure

This document details the structure of the ZSH configuration system.

## Directory Structure

```markdown
zsh/
├── .zshrc             - Main ZSH configuration file
├── .zprofile          - Login shell configuration
├── profile-zsh.zsh    - Profile configuration for ZSH
├── config/            - Configuration modules
│   ├── modules.zsh    - Module loader system
│   ├── exports.zsh    - Environment variables
│   ├── aliases.zsh    - Command aliases
│   ├── plugins.zsh    - Plugin initialization
│   ├── keybindings.zsh - Keyboard shortcuts
│   ├── helpers.zsh    - Helper functions
│   └── modules/       - Modular components
│       ├── functions/ - Shell functions by category
│       └── local/     - User-specific overrides (optional)
├── sheldon/           - Sheldon plugin manager configurations
│   ├── plugins.toml   - Plugin declarations
│   ├── fzf-tab-config.zsh - FZF tab completion config
│   ├── iterm.zsh      - iTerm2 integration
│   ├── pyenv.zsh      - Python environment manager
│   └── terminal-title.zsh - Terminal window title config
└── docs/              - Documentation
    ├── keybindings.md - Keyboard shortcuts documentation
    ├── requirements.md - Installation requirements
    └── structure.md   - This file
```

## File Naming Conventions

Module files follow the `XX-name.zsh` naming convention:

- **00-09**: Setup and initialization
- **10-69**: Core functionality, grouped by domain
- **70-89**: Reserved for future extensions
- **90-99**: Finalization and cleanup

This ensures dependencies are loaded in the correct order.

## Function Naming Conventions

All functions and variables are prefixed with `zdotfiles_` to avoid namespace collisions:

```zsh
zdotfiles_function_name() {
  # Function code
}
```
