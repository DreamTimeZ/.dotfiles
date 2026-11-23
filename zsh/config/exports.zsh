typeset -U path fpath

HISTSIZE=50000
SAVEHIST=2000000
HISTFILE="$HOME/.zsh_history"

# Atuin handles most history functionality. These stay for compatibility with
# non-Atuin shells and fallback behavior.
setopt SHARE_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
# No HIST_EXPIRE_DUPS_FIRST: HIST_IGNORE_ALL_DUPS leaves no duplicate to expire, so
# every line read past HISTSIZE scans the whole ring (100k-line file: 3.5 s, 2026-11-23).
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY

# ----- Locale -----
# AppleLocale carries a region override that LANG cannot express.
export LC_TIME=en_GB.UTF-8

if [[ -z "$COLORTERM" ]]; then
  export COLORTERM=truecolor
fi

if [[ "$TERM" == "xterm" ]] || [[ "$TERM" == "screen" ]]; then
  export TERM="${TERM}-256color"
fi

unsetopt CORRECT
export PROMPT_EOL_MARK=""     # Suppress '%' character for incomplete lines
setopt INTERACTIVE_COMMENTS

unsetopt BEEP
# iTerm2: Prefs > Profiles > Terminal > Notifications > Visual Bell

# ----- Homebrew Configuration -----
# Disable analytics - Homebrew collects anonymous usage data by default
# See: https://docs.brew.sh/Analytics
export HOMEBREW_NO_ANALYTICS=1

# NULL_GLOB is safer than NO_NOMATCH
setopt NULL_GLOB
setopt NO_CASE_GLOB
setopt GLOBSTAR_SHORT

# Per zsh version: only the version that wrote a .zwc reads it, and /bin/zsh
# and a Homebrew zsh can both start this config.
ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zcompdump-$ZSH_VERSION"
[[ -d ${ZSH_COMPDUMP%/*} ]] || mkdir -p -- "${ZSH_COMPDUMP%/*}"

if [[ -o interactive ]]; then
  autoload -Uz compinit
  compinit -C -d "$ZSH_COMPDUMP"
  # Byte-compiling the dump saves ~1.5ms per shell. With -C, compinit rewrites
  # the dump only when it is missing, so this rarely fires.
  # -U so aliases in scope are not expanded into the compiled form
  [[ -s $ZSH_COMPDUMP && ! $ZSH_COMPDUMP.zwc -nt $ZSH_COMPDUMP ]] && zcompile -UR -- "$ZSH_COMPDUMP"
fi

if [[ -o interactive ]]; then
  autoload -Uz bracketed-paste-magic
  zle -N bracketed-paste bracketed-paste-magic
fi
