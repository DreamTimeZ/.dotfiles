# Local ZSH Configurations

User-specific configurations that **won't be committed** to the repository.

## Usage

Create `.zsh` files here - they load automatically after all other modules.

### Example: `personal.zsh`

```zsh
# Enable interactive file operations for this session
use_interactive_file_ops

# Custom aliases
alias work='cd ~/Projects'
alias config='cd ~/.dotfiles'

# Machine-specific paths
export PATH="$HOME/custom-tools:$PATH"

# Sensitive variables (won't be committed)
export API_KEY="your-secret-key"
```

### Available Override Functions

```zsh
# Machine-specific path additions
export PATH="$HOME/custom-tools/bin:$PATH"

# Override command aliases
alias llg='eza -la --git --icons'
use_interactive_file_ops()  # Makes cp/mv/rm interactive by default
```

Files in this directory are loaded **last**, so they can override any previous settings.
