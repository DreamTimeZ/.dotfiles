# ===============================
# OPTIONAL TOOLS & CONFIGURATIONS
# ===============================

# ===============================
# PROMPT SETTINGS
# ===============================
# If Powerlevel10k is configured, it will override the PROMPT below.
# Uncomment the following for a basic fallback prompt:
# PROMPT='%F{blue}%n@%m:%~%f$ '

# Source additional scripts from ~/.config/zsh/
if [ -d "$HOME/.config/zsh" ]; then
    for f in "$HOME/.config/zsh/"*; do
        [ -r "$f" ] && source "$f"
    done
fi

