# Dotfiles Structure

## Path Organization

The dotfiles use a clean, organized path structure with two repositories:

```markdown
~/.dotfiles/         # Main public repository
├── bin/             # Helper scripts, installation scripts
├── docs/            # Documentation
├── git/             # Git configuration
├── hammerspoon/     # Hammerspoon configuration
│   └── hammerspoon.md  # Hammerspoon documentation
├── launchagents/    # LaunchAgent plists
│   └── launchagents.md # LaunchAgents documentation
├── nvim/            # Neovim configuration
│   └── neovim.md    # Neovim documentation
├── ssh/             # SSH configuration
├── tmux/            # Tmux configuration
│   └── tmux.md      # Tmux documentation
├── zsh/             # Zsh configuration
│   └── README.md    # Zsh documentation
├── install.sh       # Installation script
├── installation.md  # Installation guide
├── iterm2.md        # iTerm2 configuration
├── shell.md         # Shell configuration guide
├── structure.md     # This file
└── README.md        # Main documentation

~/.dotfiles-private/ # Private repository (source of truth for local files)
├── hammerspoon/config/local/  # Hammerspoon local configs
├── ssh/local/                 # SSH local configs
├── zsh/config/modules/local/  # Zsh local configs
└── ...                        # Other local configurations
```

## Local Paths

For enhanced security and performance, certain configurations are separated into user-specific paths:

```markdown
~/.local/bin/        # User-specific binaries (direct symlinks only)
~/Library/LaunchAgents/  # User-specific LaunchAgents
~/.ssh/              # SSH configuration
~/.config/           # XDG configuration directory
```

## Private Repository Integration

To keep sensitive and machine-specific configurations secure:

- **Dual Repository Setup**: Main public repo (`~/.dotfiles`) + private repo (`~/.dotfiles-private`)
- **Source of Truth**: `~/.dotfiles-private` is the authoritative source for all `local/` files
- **Symlink Strategy**: Files are symlinked from private repo to public repo's `local/` directories
- **Security Benefits**:
  - Sensitive data (API keys, tokens, machine-specific paths) never enters public repo
  - Private configurations tracked in separate git repository
  - Public repo can be safely shared and version-controlled

**Example structure:**
```bash
# Private repo contains the actual files
~/.dotfiles-private/zsh/config/modules/local/custom.zsh

# Symlinked to public repo's local directory
~/.dotfiles/zsh/config/modules/local/custom.zsh -> ~/.dotfiles-private/zsh/config/modules/local/custom.zsh
```

## Configuration Philosophy

- **Modular**: Each tool has its own directory
- **Overridable**: Local configurations via `.local` files
- **Linkable**: Symlinks connect dotfiles to system locations
- **Documented**: Each component has its own documentation
- **Portable**: Works across different macOS systems
