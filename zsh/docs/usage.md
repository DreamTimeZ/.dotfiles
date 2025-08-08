# ZSH Configuration Usage Guide

This document provides detailed information on how to use and customize the ZSH configuration system.

## Installation

1. Clone this repository to `~/.dotfiles`:

   ```bash
   git clone https://github.com/username/dotfiles.git ~/.dotfiles
   ```

2. Create symlinks for ZSH configuration:

   ```bash
   ln -sf ~/.dotfiles/zsh/.zshrc ~/.zshrc
   ln -sf ~/.dotfiles/zsh/.zprofile ~/.zprofile
   ```

## Customization

### Environment Variables

Add custom environment variables to `exports.zsh`:

```zsh
# In ~/.dotfiles/zsh/config/exports.zsh
export MY_CUSTOM_VARIABLE="value"
```

### Aliases

Add custom command aliases to `aliases.zsh`:

```zsh
# In ~/.dotfiles/zsh/config/aliases.zsh
alias myalias='command --flag'
```

### Functions

Add functions to the appropriate category file in `modules/functions/`:

```zsh
# In ~/.dotfiles/zsh/config/modules/functions/20-git.zsh
zdotfiles_git_checkout_branch() {
  # Function implementation
}

# Export the function
typeset -fx zdotfiles_git_checkout_branch
```

### Plugin Configuration

Add or modify plugin configurations in the `sheldon/` directory:

```zsh
# Edit ~/.dotfiles/zsh/sheldon/plugins.toml to add plugins
# Or create custom configuration files in the sheldon directory
```

### Local Overrides

Create files in `modules/local/` for machine-specific configurations:

```zsh
# Create ~/.dotfiles/zsh/config/modules/local/machine.zsh
# These will be loaded last and can override any previously loaded settings
```

## Debug Mode

Enable debug output to troubleshoot configuration:

```bash
export ZDOTFILES_DEBUG=1
```

Then start a new shell or reload with `source ~/.zshrc`.

## Common Tasks

### Adding Path Entries

Use the safe path management functions:

```zsh
# Add to end of PATH
zdotfiles_path_append "/path/to/add"

# Add to beginning of PATH
zdotfiles_path_prepend "/path/to/add"
```

## Performance Optimization

The configuration is designed for minimal startup time:

- Modular loading with precise dependencies
- Exported functions only when needed
- Add to the start of `.zshrc`: `zmodload zsh/zprof` and on the end `zprof` to analyze performance
- Restart iTerm and do `hyperfine "zsh -i -c exit" --warmup 3` to check startup time
