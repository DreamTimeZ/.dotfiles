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
    ```

3. **Setup Neovim**:

    ```bash
    mkdir -p ~/.config/nvim
    ln -sf ~/.dotfiles/nvim/init.lua ~/.config/nvim/init.lua
    ```

4. **Setup Tmux**:

    ```bash
    ln -sf ~/.dotfiles/tmux/.tmux.conf ~/.tmux.conf
    ```

5. **Setup Git**:

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

6. **Setup SSH**:

    ```bash
    mkdir -p ~/.ssh
    ln -sf ~/.dotfiles/ssh/config ~/.ssh/config

    # Create local SSH config (if not exists)
    if [ ! -f ~/.dotfiles/ssh/config.local ]; then
      cat > ~/.dotfiles/ssh/config.local <<EOL
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

7. **Setup Hammerspoon**:

    ```bash
    brew install --cask hammerspoon
    ln -sf ~/.dotfiles/hammerspoon ~/.hammerspoon
    
    # Ensure the init.lua is directly in ~/.hammerspoon
    # If not, you may need to remove the existing directory:
    # rm -rf ~/.hammerspoon && ln -s ~/.dotfiles/hammerspoon ~/.hammerspoon
    ```

8. **Setup LaunchAgents**:

    ```bash
    mkdir -p ~/Library/LaunchAgents
    for plist in ~/.dotfiles/launchagents/*.plist; do
      ln -sf "$plist" ~/Library/LaunchAgents/
      launchctl unload "$plist" 2>/dev/null || true
      launchctl load "$plist"
    done
    ```

9. **Install iTerm2 Shell Integration** (optional):

    ```bash
    curl -L https://iterm2.com/shell_integration/zsh -o ~/.iterm2_shell_integration.zsh
    ```

10. **Secure Important Directories**:

    ```bash
    # Restrict write permissions on Zsh function path directory
    chmod go-w "$(dirname ${fpath[1]})"

    # Restrict write permissions on the cache directory
    chmod go-w "${XDG_CACHE_HOME:-$HOME/.cache}"
    ```

## Local Customization

The configuration supports local overrides through `.local` files:

- `git/.gitconfig.local`: Git user info and machine-specific settings
- `ssh/config.local`: Machine-specific SSH configurations

These files are ignored by Git to keep sensitive information private. 