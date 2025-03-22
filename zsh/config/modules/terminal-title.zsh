# ===============================
# TERMINAL TITLE CONFIGURATION
# ===============================

# Called before command execution
preexec() {
  # Escape problematic characters in the command
  local cmd=$(echo "$1" | tr -d '\e\a')
  echo -ne "\e]2;CMD: ${cmd:0:60}\a" # Window title shows running command
}

# Called before each prompt
precmd() {
  local proj="$(basename "$PWD")"
  echo -ne "\e]1;Project: $proj\a"  # Tab title shows current project name
  print -Pn "\e]2;%n@%m: %~\a"      # Window title shows user@host: path (when no command is running)
}