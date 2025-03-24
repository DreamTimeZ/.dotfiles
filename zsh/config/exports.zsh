# ===============================
# Environment Variables and Options
# ===============================

# ----- History Configuration -----
HISTSIZE=50000                # Maximum number of events in memory
SAVEHIST=2000000              # Maximum number of events saved to history file
HISTFILE="$HOME/.zsh_history" # History file location
setopt INC_APPEND_HISTORY     # Append commands as you type them
setopt APPEND_HISTORY         # Append to history rather than overwrite
setopt SHARE_HISTORY          # Share history among all sessions
setopt EXTENDED_HISTORY       # Record timestamp with each command
setopt HIST_REDUCE_BLANKS     # Remove extra whitespace from history
setopt HIST_IGNORE_ALL_DUPS   # Do not record duplicate entries
setopt HIST_IGNORE_SPACE      # Ignore commands that start with a space

# ----- Miscellaneous Options -----
# CORRECT_ALL: You want aggressive typo correction everywhere (command, args, paths). Often overkill.
# CORRECT: You want smart correction of just command names, low false positives.
setopt CORRECT                # Auto-correct minor errors in commands and paths
setopt PROMPT_SP
setopt NO_CASE_GLOB           # Enable case-insensitive globbing
setopt GLOBSTAR_SHORT         # Enable recursive globbing with **

# ----- Auto-completion -----
autoload -Uz compinit && compinit

# Prevents automatic command execution on paste and 
# ensures proper handling of newlines, empty lines, and special characters in pasted text
autoload -Uz bracketed-paste-magic
zle -N bracketed-paste bracketed-paste-magic

