# ===============================
# TERMINAL TITLE CONFIGURATION
# ===============================
# Sets dynamic terminal title based on current command and directory

# Only run in interactive shells and when terminal supports title setting
if [[ $- == *i* ]] && ([[ "$TERM" == xterm* ]] || [[ "$TERM" == rxvt* ]] || [[ "$TERM" == screen* ]] || [[ "$TERM" == tmux* ]]); then
  # Use typeset to declare local variables with better performance
  typeset -g _last_cmd=""
  typeset -g _last_pwd=""
  typeset -g _last_proj=""
  typeset -g _update_interval=1  # Only update every second

  # Use add-zsh-hook to avoid clobbering other preexec/precmd handlers
  autoload -Uz add-zsh-hook

  _tt_preexec() {
    # Only update if command changed and non-empty
    if [[ -n "$1" && "$1" != "$_last_cmd" ]]; then
      _last_cmd="$1"
      
      # Make a clean copy of the command for display
      local cmd="$1"
      
      # Safely remove escape sequences without losing characters
      cmd="${cmd//[$'\001'-$'\037']/}"
      
      # Truncate command if too long and add ellipsis
      local max_length=50
      local truncated=""
      
      if (( ${#cmd} > $max_length )); then
        truncated="${cmd:0:$max_length}..."
      else
        truncated="$cmd"
      fi
      
      # Set terminal title using print with proper escaping to avoid PROMPT_SP
      print -Pn "\e]0;CMD: ${truncated}\a" > /dev/tty
    fi
  }

  _tt_precmd() {
    # Rate limiting - only update every _update_interval seconds
    if (( SECONDS - _last_update > _update_interval )) || [[ "$PWD" != "$_last_pwd" ]]; then
      _last_update=$SECONDS
      _last_pwd="$PWD"
      # Use parameter expansion for dirname (faster than command substitution)
      _last_proj="${PWD##*/}"
      # Set terminal title using print with proper escaping to avoid PROMPT_SP
      print -Pn "\e]1;Project: ${_last_proj}\a\e]2;%n@%m: %~\a" > /dev/tty
    fi
  }
  
  # Register hooks once
  if [[ -z ${_tt_hooks_installed-} ]]; then
    typeset -g _tt_hooks_installed=1
    add-zsh-hook preexec _tt_preexec
    add-zsh-hook precmd _tt_precmd
  fi
  
  # Initialize the update timer
  typeset -g _last_update=$SECONDS
fi