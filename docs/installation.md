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
    # Clean login
    ln -sf ~/.dotfiles/shell/.hushlogin ~/.hushlogin

    # Tmux session layouts
    mkdir -p ~/.config/tmuxinator && ln -sf ~/.dotfiles/tmuxinator/default.yml ~/.config/tmuxinator/default.yml
    ```

5. **Setup System Customization**:

    ```bash
    # Karabiner keyboard remapping
    mkdir -p ~/.config/karabiner && ln -sf ~/.dotfiles/karabiner/karabiner.json ~/.config/karabiner/karabiner.json
    
    # Espanso text expansion (setup from templates)
    cd ~/.dotfiles/espanso/templates && for f in *.template; do cp "$f" "../local/${f%.template}"; done
    mkdir -p ~/.config/espanso/{config,match}
    ln -sf ~/.dotfiles/espanso/local/default.yml ~/.config/espanso/config/default.yml
    ln -sf ~/.dotfiles/espanso/local/base.yml ~/.config/espanso/match/base.yml
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
    if [ ! -f ~/.dotfiles/git/.gitconfig.local ]; then
      cat > ~/.dotfiles/git/.gitconfig.local <<EOL
    [user]
        name = Your Name
        email = your.email@example.com
    EOL
    fi
    ```

9. **Setup SSH**:

    ```bash
    mkdir -p ~/.ssh
    ln -sf ~/.dotfiles/ssh/config ~/.ssh/config

    # Create local SSH config (if not exists)
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

11. **Setup LaunchAgents**:

    ```bash
    mkdir -p ~/Library/LaunchAgents
    for plist in ~/.dotfiles/launchagents/*.plist; do
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

### Local Override Files (.local)

- `git/local/.gitconfig.local`: Git user info and machine-specific settings
- `ssh/local/config.local`: Machine-specific SSH configurations
- `zsh/config/modules/local/*.zsh`: Machine-specific shell functions and aliases

### Managed Configuration Files

The dotfiles manage configuration files for various tools:

- **Shell Integration**: Powerlevel10k prompt theme, FZF fuzzy finder, iTerm2 integration
- **Development Tools**: tealdeer (tldr), direnv (environment), tmuxinator (sessions)
- **Shell Management**: Atuin (shell history), Sheldon (plugin management), hushlogin (clean login)
- **System Customization**: Karabiner (keyboard remapping), Espanso (text expansion)

All managed files are symlinked from their respective tool directories in `~/.dotfiles/` to their expected locations.
