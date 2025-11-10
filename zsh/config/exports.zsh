# ===============================
# Environment Variables and Options
# ===============================

# Ensure PATH and FPATH are unique (prevents duplicates when prepending/appending)
typeset -U path fpath

# ----- History Configuration -----
HISTSIZE=50000                # Maximum number of events in memory per session
SAVEHIST=2000000              # Maximum number of events saved to history file
HISTFILE="$HOME/.zsh_history" # History file location

# History settings (Atuin handles most history functionality now)
# Keep these for compatibility with non-Atuin shells and fallback behavior
setopt SHARE_HISTORY          # Share history among all sessions (includes incremental append)
setopt EXTENDED_HISTORY       # Record timestamp with each command
setopt HIST_IGNORE_ALL_DUPS   # Do not record duplicate entries
setopt HIST_SAVE_NO_DUPS      # Do not save duplicate entries
setopt HIST_EXPIRE_DUPS_FIRST # Expire duplicates first when trimming history
setopt HIST_IGNORE_SPACE      # Ignore commands that start with a space (Atuin also filters these)
setopt HIST_REDUCE_BLANKS     # Remove extra whitespace from history
setopt HIST_VERIFY            # Show command with history expansion to user before running it

# ----- Terminal Configuration -----
# Enable true color (24-bit) support - only set if not already configured
# Modern terminals (iTerm2, Alacritty, WezTerm, Kitty) often set this automatically
if [[ -z "$COLORTERM" ]]; then
  export COLORTERM=truecolor
fi

# Only override TERM if it's not already set to a 256-color or better variant
# Most modern terminals set this correctly, but some environments (like basic SSH) may need help
if [[ "$TERM" == "xterm" ]] || [[ "$TERM" == "screen" ]]; then
  export TERM="${TERM}-256color"
fi

# ----- Miscellaneous Options -----
# CORRECT_ALL: You want aggressive typo correction everywhere (command, args, paths). Often overkill.
# CORRECT: You want smart correction of just command names, low false positives.
# Disabled - use thefuck instead with 'f', 'fk', or 'fuck' commands
unsetopt CORRECT              # Disable auto-correct prompts
# Prompt handling - Global solution for '%' character from incomplete output
export PROMPT_EOL_MARK=""     # Suppress '%' character for incomplete lines
setopt INTERACTIVE_COMMENTS   # Allow comments in interactive shell (improves usability)

# ----- Bell Configuration -----
unsetopt BEEP                 # Disable audio bell in zsh
# iTerm2: Prefs > Profiles > Terminal > Notifications > Visual Bell

# Glob handling - NULL_GLOB is safer than NO_NOMATCH
setopt NULL_GLOB              # Remove non-matching patterns instead of erroring or keeping them literal
setopt NO_CASE_GLOB           # Enable case-insensitive globbing
setopt GLOBSTAR_SHORT         # Enable recursive globbing with **

# ----- Auto-completion -----
# Initialize completion system in interactive shells only
ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zcompdump"
mkdir -p -- "${ZSH_COMPDUMP%/*}"

if [[ -o interactive ]]; then
  autoload -Uz compinit
  compinit -C -d "$ZSH_COMPDUMP"  # -C skips security check for faster startup
fi

# First-time setup (optional): run once to silence compaudit warnings
# chmod -R go-w "$(dirname ${fpath[1]})"

# Prevents automatic command execution on paste and
# ensures proper handling of newlines, empty lines, and special characters in pasted text
if [[ -o interactive ]]; then
  autoload -Uz bracketed-paste-magic
  zle -N bracketed-paste bracketed-paste-magic
fi

# ----- PATH Management -----
# NOTE: Static PATH entries are managed in .zprofile to prevent duplication in subshells