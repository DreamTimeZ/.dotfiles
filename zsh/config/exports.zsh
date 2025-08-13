# ===============================
# Environment Variables and Options
# ===============================

# Ensure PATH and FPATH are unique (prevents duplicates when prepending/appending)
typeset -U path fpath

# ----- History Configuration -----
HISTSIZE=50000                # Maximum number of events in memory per session
SAVEHIST=2000000              # Maximum number of events saved to history file
HISTFILE="$HOME/.zsh_history" # History file location

# History sharing and persistence (SHARE_HISTORY includes INC_APPEND_HISTORY)
setopt SHARE_HISTORY          # Share history among all sessions (includes incremental append)
setopt EXTENDED_HISTORY       # Record timestamp with each command

# Duplicate handling
setopt HIST_IGNORE_ALL_DUPS   # Do not record duplicate entries
setopt HIST_SAVE_NO_DUPS      # Do not save duplicate entries
setopt HIST_EXPIRE_DUPS_FIRST # Expire duplicates first when trimming history

# Content filtering
setopt HIST_IGNORE_SPACE      # Ignore commands that start with a space
setopt HIST_REDUCE_BLANKS     # Remove extra whitespace from history
setopt HIST_VERIFY            # Show command with history expansion to user before running it

# ----- Miscellaneous Options -----
# CORRECT_ALL: You want aggressive typo correction everywhere (command, args, paths). Often overkill.
# CORRECT: You want smart correction of just command names, low false positives.
setopt CORRECT                # Auto-correct minor errors in commands and paths
setopt PROMPT_SP              # Print a carriage return just before printing a prompt

# Interactive shell enhancements
setopt INTERACTIVE_COMMENTS   # Allow comments in interactive shell (improves usability)

# Bell configuration - visual feedback only, no audio disruption
unsetopt BEEP                 # Disable audio bell
# Note: Configure visual bell in your terminal emulator (iTerm2: Prefs > Profiles > Advanced > Visual Bell)
# This gives you visual feedback without audio noise

# Glob handling - NULL_GLOB is safer than NO_NOMATCH
setopt NULL_GLOB              # Remove non-matching patterns instead of erroring or keeping them literal
setopt NO_CASE_GLOB           # Enable case-insensitive globbing
setopt GLOBSTAR_SHORT         # Enable recursive globbing with **

# ----- Auto-completion -----
# Use custom compdump path in XDG_CACHE_HOME (faster and more organized)
ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zcompdump"

# Ensure cache directory exists
mkdir -p -- "${ZSH_COMPDUMP%/*}"

# Optional: run ONCE manually if not done yet to silence compaudit forever
# chmod -R go-w "$(dirname ${fpath[1]})"

# Only initialize completion in interactive shells
if [[ -o interactive ]]; then
  autoload -Uz compinit
  compinit -C -d "$ZSH_COMPDUMP" # Uses cache and skips compaudit
fi

# Prevents automatic command execution on paste and
# ensures proper handling of newlines, empty lines, and special characters in pasted text
if [[ -o interactive ]]; then
  autoload -Uz bracketed-paste-magic
  zle -N bracketed-paste bracketed-paste-magic
fi

