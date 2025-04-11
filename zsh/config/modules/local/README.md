# Local ZSH Configurations

This directory is for **local**, user-specific ZSH configurations that should not be committed to the repository.

## Purpose

- Override settings from other modules
- Add machine-specific configurations
- Define sensitive environment variables
- Add personal aliases or functions

## Usage

Simply create `.zsh` files in this directory. They will be loaded automatically after all other modules.

Example file: `personal.zsh`

```zsh
# Machine-specific path additions
export PATH="$HOME/custom-tools/bin:$PATH"

# Override command aliases
alias llg='eza -la --git --icons'
```
