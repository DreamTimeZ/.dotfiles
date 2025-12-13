# Installation Guide

## Automated Setup (COMING SOON!)

```bash
curl -fsSL https://raw.githubusercontent.com/DreamTimeZ/dotfiles-macos/main/install.sh | bash
```

Or clone and run the installer:

```bash
git clone git@github.com:DreamTimeZ/dotfiles-macos.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

## Manual Setup

1. **Clone the repository**:

    ```bash
    git clone git@github.com:DreamTimeZ/dotfiles-macos.git ~/.dotfiles
    ```

2. **Setup Shell Configuration**:

    ```bash
    # Zsh
    ln -sf ~/.dotfiles/zsh/.zshrc ~/.zshrc
    ln -sf ~/.dotfiles/zsh/.zprofile ~/.zprofile

    # Sheldon (Zsh plugin manager)
    mkdir -p ~/.config/sheldon
    ln -sf ~/.dotfiles/zsh/sheldon/plugins.toml ~/.config/sheldon/plugins.toml
    sheldon lock --update
    
    # Atuin (shell history) - auto-configured on first shell load
    # Config will be auto-symlinked from ~/.dotfiles/zsh/config/atuin/config.toml
    ```

3. **Setup Shell Tool Configurations**:

    ```bash
    # Powerlevel10k prompt theme
    ln -sf ~/.dotfiles/p10k/.p10k.zsh ~/.p10k.zsh
    
    # FZF fuzzy finder
    ln -sf ~/.dotfiles/fzf/.fzf.zsh ~/.fzf.zsh
    
    # iTerm2 shell integration
    ln -sf ~/.dotfiles/iterm2/.iterm2_shell_integration.zsh ~/.iterm2_shell_integration.zsh
    
    # Development tools
    mkdir -p ~/.config/tealdeer && ln -sf ~/.dotfiles/tealdeer/config.toml ~/.config/tealdeer/config.toml
    mkdir -p ~/.config/direnv && ln -sf ~/.dotfiles/direnv/config.toml ~/.config/direnv/direnv.toml
    ```

4. **Setup Shell Environment**:

    ```bash
    # Tmux session layouts
    mkdir -p ~/.config/tmuxinator && ln -sf ~/.dotfiles/tmuxinator/default.yml ~/.config/tmuxinator/default.yml
    ```

5. **Setup System Customization**:

    ```bash
    # Karabiner keyboard remapping (macOS only)
    mkdir -p ~/.config/karabiner && ln -sf ~/.dotfiles/karabiner/karabiner.json ~/.config/karabiner/karabiner.json

    # Espanso text expansion (setup from templates)
    cd ~/.dotfiles/espanso/templates && for f in *.template; do cp "$f" "../local/${f%.template}"; done

    # Choose based on your OS:

    # Linux/macOS:
    ESPANSO_PATH="$HOME/.config/espanso"
    mkdir -p "$ESPANSO_PATH"/{config,match}

    # Remove default base.yml if it exists (we'll use our own from local/match/)
    [[ -f "$ESPANSO_PATH/config/base.yml" ]] && rm "$ESPANSO_PATH/config/base.yml"

    # Symlink config files from local/config/ (default.yml, etc.)
    if [[ -d ~/.dotfiles/espanso/local/config ]]; then
      for f in ~/.dotfiles/espanso/local/config/*.yml; do
        [[ -f "$f" ]] && ln -sf "$f" "$ESPANSO_PATH/config/$(basename "$f")"
      done
    fi

    # Symlink match files from local/match/ (both .yml and .md files)
    if [[ -d ~/.dotfiles/espanso/local/match ]]; then
      for f in ~/.dotfiles/espanso/local/match/*.{yml,md}; do
        [[ -f "$f" ]] && [[ "$(basename "$f")" != "README.md" ]] && ln -sf "$f" "$ESPANSO_PATH/match/$(basename "$f")"
      done
    fi

    # Windows (WSL - use Windows path):
    # ESPANSO_PATH="$APPDATA/espanso"
    # mkdir -p "$ESPANSO_PATH"/{config,match}
    #
    # # Remove default base.yml if it exists (we'll use our own from local/match/)
    # [[ -f "$ESPANSO_PATH/config/base.yml" ]] && rm "$ESPANSO_PATH/config/base.yml"
    #
    # # Symlink config files from local/config/ (default.yml, etc.)
    # if [[ -d ~/.dotfiles/espanso/local/config ]]; then
    #   for f in ~/.dotfiles/espanso/local/config/*.yml; do
    #     [[ -f "$f" ]] && ln -sf "$f" "$ESPANSO_PATH/config/$(basename "$f")"
    #   done
    # fi
    #
    # # Symlink match files from local/match/ (both .yml and .md files)
    # if [[ -d ~/.dotfiles/espanso/local/match ]]; then
    #   for f in ~/.dotfiles/espanso/local/match/*.{yml,md}; do
    #     [[ -f "$f" ]] && [[ "$(basename "$f")" != "README.md" ]] && ln -sf "$f" "$ESPANSO_PATH/match/$(basename "$f")"
    #   done
    # fi
    ```

6. **Setup Neovim**:

    ```bash
    mkdir -p ~/.config/nvim
    ln -sf ~/.dotfiles/nvim/init.lua ~/.config/nvim/init.lua
    ```

7. **Setup Tmux**:

    ```bash
    ln -sf ~/.dotfiles/tmux/.tmux.conf ~/.tmux.conf
    ```

8. **Setup Git**:

    ```bash
    ln -sf ~/.dotfiles/git/.gitconfig ~/.gitconfig
    ln -sf ~/.dotfiles/git/.gitignore_global ~/.gitignore_global

    # Create local Git config (if not exists)
    mkdir -p ~/.dotfiles/git/local
    if [ ! -f ~/.dotfiles/git/local/.gitconfig.local ]; then
      cat > ~/.dotfiles/git/local/.gitconfig.local <<EOL
    [user]
        name = Your Name
        email = your.email@example.com
    EOL
    fi

    # Link local config to home directory
    ln -sf ~/.dotfiles/git/local/.gitconfig.local ~/.gitconfig.local
    ```

9. **Setup SSH**:

    ```bash
    mkdir -p ~/.ssh
    ln -sf ~/.dotfiles/ssh/config ~/.ssh/config

    # Create local SSH config (if not exists)
    mkdir -p ~/.dotfiles/ssh/local
    if [ ! -f ~/.dotfiles/ssh/local/config.local ]; then
      cat > ~/.dotfiles/ssh/local/config.local <<EOL
    # Local SSH configurations - Example private server
    Host myserver
        HostName server.example.com
        User admin
        Port 22
        IdentityFile ~/.ssh/id_ed25519_server
        AddKeysToAgent yes
        UseKeychain yes
        ForwardAgent yes
        ServerAliveInterval 60
        ServerAliveCountMax 10
    EOL
    fi

    # Link local config to SSH directory
    ln -sf ~/.dotfiles/ssh/local/config.local ~/.ssh/config.local

    # Set proper permissions for SSH files
    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/config*
    ```

10. **Setup Hammerspoon**:

    ```bash
    brew install --cask hammerspoon
    ln -sf ~/.dotfiles/hammerspoon ~/.hammerspoon
    
    # Ensure the init.lua is directly in ~/.hammerspoon
    # If not, you may need to remove the existing directory:
    # rm -rf ~/.hammerspoon && ln -s ~/.dotfiles/hammerspoon ~/.hammerspoon
    ```

11. **Setup LaunchAgents** (optional - add your own plist files first):

    ```bash
    # Add .plist files to ~/.dotfiles/launchagents/ then run:
    mkdir -p ~/Library/LaunchAgents
    for plist in ~/.dotfiles/launchagents/*.plist; do
      [ -f "$plist" ] || continue
      ln -sf "$plist" ~/Library/LaunchAgents/
      launchctl unload "$plist" 2>/dev/null || true
      launchctl load "$plist"
    done
    ```

12. **Secure Important Directories**:

    ```bash
    # Restrict write permissions on Zsh function path directory
    chmod go-w "$(dirname ${fpath[1]})"

    # Restrict write permissions on the cache directory
    chmod go-w "${XDG_CACHE_HOME:-$HOME/.cache}"
    ```

## Local Customization & Security

The configuration supports local overrides and secure handling of sensitive data:

### Local Override Files

- `git/local/.gitconfig.local`: Git user info and machine-specific settings (symlinked to `~/.gitconfig.local`)
- `ssh/local/config.local`: Machine-specific SSH configurations (symlinked to `~/.ssh/config.local`)
- `zsh/config/modules/local/*.zsh`: Machine-specific shell functions and aliases
- `hammerspoon/modules/hotkeys/config/local/*`: Machine-specific Hammerspoon hotkey configurations

### Managed Configuration Files

The dotfiles manage configuration files for various tools:

- **Shell Integration**: Powerlevel10k prompt theme, FZF fuzzy finder, iTerm2 integration
- **Development Tools**: tealdeer (tldr), direnv (environment), tmuxinator (sessions)
- **Shell Management**: Atuin (shell history), Sheldon (plugin management)
- **System Customization**: Karabiner (keyboard remapping), Espanso (text expansion)

All managed files are symlinked from their respective tool directories in `~/.dotfiles/` to their expected locations.
