# ===============================
# Zsh & Tool Plugins Initialization
# ===============================

# Initialize zoxide for fast navigation (zsh version)
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init zsh)"
fi

# Initialize fzf (Zsh version)
if [ -f ~/.fzf.zsh ]; then
    source ~/.fzf.zsh
fi

# Load zsh-syntax-highlighting (installed via Homebrew)
if [ -f "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
    source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# Load zsh-autosuggestions (installed via Homebrew)
if [ -f "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
    source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# Load powerlevel10k theme
if [ -f "$(brew --prefix powerlevel10k)/share/powerlevel10k/powerlevel10k.zsh-theme" ]; then
    source "$(brew --prefix powerlevel10k)/share/powerlevel10k/powerlevel10k.zsh-theme"
fi

# Initialize asdf version manager
if [ -f "$(brew --prefix asdf)/libexec/asdf.sh" ]; then
    source "$(brew --prefix asdf)/libexec/asdf.sh"
fi

# Initialize direnv
if command -v direnv &>/dev/null; then
    eval "$(direnv hook zsh)"
fi
