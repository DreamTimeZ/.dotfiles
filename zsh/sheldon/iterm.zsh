# Lazy-load iTerm2 Shell Integration
function iterm2_shell_integration() {
  unfunction iterm2_shell_integration
  [[ -f "$HOME/.iterm2_shell_integration.zsh" ]] && source "$HOME/.iterm2_shell_integration.zsh"
}

# Add iterm2 commands to trigger lazy loading
alias imgcat='iterm2_shell_integration && imgcat'
alias imgls='iterm2_shell_integration && imgls'
alias it2attention='iterm2_shell_integration && it2attention'
alias it2check='iterm2_shell_integration && it2check'
alias it2copy='iterm2_shell_integration && it2copy'
alias it2dl='iterm2_shell_integration && it2dl'
alias it2getvar='iterm2_shell_integration && it2getvar'
alias it2setcolor='iterm2_shell_integration && it2setcolor'
alias it2setkeylabel='iterm2_shell_integration && it2setkeylabel'
alias it2ul='iterm2_shell_integration && it2ul'
alias it2universion='iterm2_shell_integration && it2universion'