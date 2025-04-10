# Dotfiles Structure

## Path Organization

The dotfiles use a clean, organized path structure:

```markdown
~/.dotfiles/         # Main repository
├── bin/             # Helper scripts, installation scripts
├── docs/            # Documentation
├── git/             # Git configuration
├── hammerspoon/     # Hammerspoon configuration
├── launchagents/    # LaunchAgent plists
├── nvim/            # Neovim configuration
├── ssh/             # SSH configuration
├── tmux/            # Tmux configuration
├── zsh/             # Zsh configuration
├── install.sh       # Installation script
└── README.md        # Main documentation
```

## Local Paths

For enhanced security and performance, certain configurations are separated into user-specific paths:

```markdown
~/.local/bin/        # User-specific binaries (direct symlinks only)
~/Library/LaunchAgents/  # User-specific LaunchAgents
~/.ssh/              # SSH configuration
~/.config/           # XDG configuration directory
```

## Configuration Philosophy

- **Modular**: Each tool has its own directory
- **Overridable**: Local configurations via `.local` files
- **Linkable**: Symlinks connect dotfiles to system locations
- **Documented**: Each component has its own documentation
- **Portable**: Works across different macOS systems
