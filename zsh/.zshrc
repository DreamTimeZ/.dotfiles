# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
# username: ${(%):-%n} -> vscode extensions mostly are for bash and do not understand zsh

# zsh-specific syntax — do not format below block
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ===============================
# SOURCE CONFIGURATION FILES
# ===============================
# Define configuration directory
DOTFILES_DIR="$HOME/.dotfiles"
ZSH_CONFIG_DIR="$DOTFILES_DIR/zsh/config"

# Source configuration files in specific order
# 1. Environment variables and options first (fundamental settings)
# 2. Plugins and tools initialization
# 3. Keybindings (must be after plugins to override their bindings)
# 4. Aliases for daily use
# 5. Functions
# 6. Extra and optional configurations

files=(
  "exports.zsh"     # Environment variables and options
  "plugins.zsh"     # Plugin initialization
  "keybindings.zsh" # Custom key bindings (after plugins)
  "aliases.zsh"     # Command aliases
  "functions.zsh"   # Custom functions
  "extras.zsh"      # Optional configurations
)

for file in "${files[@]}"; do
  config_file="$ZSH_CONFIG_DIR/$file"
  if [[ -r "$config_file" ]]; then
    source "$config_file"
  fi
done

# ===============================
# P10K CONFIGURATION (must be at the end)
# ===============================
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
if [[ -f ~/.p10k.zsh ]]; then
  source ~/.p10k.zsh
else
  PROMPT='%F{blue}%n@%m:%~%f$ '
fi