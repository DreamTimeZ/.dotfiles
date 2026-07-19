# Dotfiles Structure

## Path Organization

The dotfiles use a clean, organized path structure with two repositories:

```markdown
~/.dotfiles/         # Main public repository
├── bin/             # Helper scripts, installation scripts
├── docs/            # Documentation
├── espanso/         # Espanso text expansion
│   └── README.md    # Espanso documentation
├── ghostty/         # Ghostty terminal configuration
├── git/             # Git configuration
├── gpg/             # GnuPG configuration
│   └── README.md    # GnuPG documentation
├── hammerspoon/     # Hammerspoon configuration
│   └── README.md       # Hammerspoon documentation
├── iterm2/          # iTerm2 shell integration (legacy, superseded by ghostty/)
├── karabiner/       # Karabiner-Elements key remapping
├── launchagents/    # LaunchAgent plists
│   └── launchagents.md # LaunchAgents documentation
├── mise/            # mise tool-version management
├── nilesoft/        # Nilesoft Shell context menu (Windows)
│   └── README.md    # Nilesoft documentation
├── nvim/            # Neovim configuration
│   └── neovim.md    # Neovim documentation
├── p10k/            # Powerlevel10k prompt configuration
├── packages/        # Package manifests (Brewfile per install group, apt/cargo lists)
├── ssh/             # SSH configuration
├── tlrc/            # tldr client configuration
├── tmux/            # Tmux configuration
│   └── tmux.md      # Tmux documentation
├── zsh/             # Zsh configuration
│   ├── README.md    # Zsh documentation
│   └── docs/        # Detailed Zsh docs (features, keybindings, usage, ...)
├── setup.sh         # Installation and setup script
└── README.md        # Main documentation

~/.dotfiles-private/ # Private repository (source of truth for local files)
├── git/local/                 # Git local configs
├── ssh/local/                 # SSH local configs
├── hammerspoon/config/local/  # Hammerspoon local configs
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
