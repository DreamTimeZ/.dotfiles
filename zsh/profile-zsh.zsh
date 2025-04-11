#!/bin/zsh
# ===============================
# ZSH PROFILING SCRIPT
# ===============================
# Usage: source ~/.dotfiles/zsh/profile-zsh.zsh
# Shows detailed performance metrics for zsh startup

# Define colors for better readability
NC='\033[0m'           # No Color
RED='\033[0;31m'       # Red
GREEN='\033[0;32m'     # Green
YELLOW='\033[0;33m'    # Yellow
BLUE='\033[0;34m'      # Blue
BOLD='\033[1m'         # Bold

# Set up log files
ZDOTFILES_PROFILE_LOG="/tmp/zsh_module_profile.log"
SHELDON_PROFILE_LOG="/tmp/zsh_sheldon_profile.log"
OVERALL_PROFILE_LOG="/tmp/zsh_overall_profile.log"

# Modify the modules.zsh file temporarily to log all module load times to a file
setup_module_profiling() {
  local modules_file="$ZDOTFILES_CONFIG_DIR/modules.zsh"
  local backup_file="$modules_file.bak"
  
  # Create backup if it doesn't exist
  if [[ ! -f $backup_file ]]; then
    cp "$modules_file" "$backup_file"
    echo "Created backup of modules.zsh at $backup_file"
  fi
  
  # Create profiling version of modules.zsh
  cat > "$modules_file" << 'EOF'
# ===============================
# ZSH MODULES LOADER (PROFILING VERSION)
# ===============================

# Ensure we have the current directory where this script resides
typeset -g ZDOTFILES_MODULES_BASE="${0:A:h}/modules"
typeset -g ZDOTFILES_PROFILE_LOG="/tmp/zsh_module_profile.log"

# Clear the log file
: > "$ZDOTFILES_PROFILE_LOG"

# ===============================
# HELPER FUNCTIONS
# ===============================

# Validate directory exists and is readable
zdotfiles_validate_dir() {
  [[ -d "$1" && -r "$1" ]] && return 0 || return 1
}

# Helper to load all .zsh files in a directory with error handling
zdotfiles_load_dir() {
  local dir="$1"
  local dir_name=$(basename "$dir")
  local dir_start=$(($(date +%s%N)/1000000))
  
  if ! zdotfiles_validate_dir "$dir"; then
    return 1
  fi
  
  # Silent operation - log to file only, no console output
  echo "dir:$dir_name:start:$dir_start" >> "$ZDOTFILES_PROFILE_LOG"
  
  # First load all numerically-prefixed files in order (00-99)
  for module in "$dir"/[0-9][0-9]-*.zsh(N.on); do
    local mod_name=$(basename "$module")
    local start=$(($(date +%s%N)/1000000))
    source "$module" 2>/dev/null
    local end=$(($(date +%s%N)/1000000))
    local elapsed=$((end-start))
    echo "file:$dir_name:$mod_name:$elapsed" >> "$ZDOTFILES_PROFILE_LOG"
  done
  
  # Load any remaining modules without numerical prefix
  for module in "$dir"/*.zsh(N); do
    # Skip if file has a numerical prefix (already loaded)
    if [[ ! "$(basename "$module")" =~ ^[0-9][0-9]- ]]; then
      local mod_name=$(basename "$module")
      local start=$(($(date +%s%N)/1000000))
      source "$module" 2>/dev/null
      local end=$(($(date +%s%N)/1000000))
      local elapsed=$((end-start))
      echo "file:$dir_name:$mod_name:$elapsed" >> "$ZDOTFILES_PROFILE_LOG"
    fi
  done
  
  local dir_end=$(($(date +%s%N)/1000000))
  local dir_elapsed=$((dir_end-dir_start))
  echo "dir:$dir_name:end:$dir_elapsed" >> "$ZDOTFILES_PROFILE_LOG"
  
  return 0
}

# ===============================
# MAIN LOADING PROCESS
# ===============================

# 1. Load function modules (utilities)
zdotfiles_load_dir "$ZDOTFILES_MODULES_BASE/functions"

# 2. Load plugin configuration modules
zdotfiles_load_dir "$ZDOTFILES_MODULES_BASE/plugins"

# 3. Load any future module types (example: lib)
# zdotfiles_load_dir "$ZDOTFILES_MODULES_BASE/lib" "library"

# 4. Use local module overrides if they exist
zdotfiles_load_dir "$ZDOTFILES_MODULES_BASE/local"

# Don't expose loader internals
unset -f zdotfiles_load_dir zdotfiles_validate_dir 
EOF
}

# Set up sheldon profiling
setup_sheldon_profiling() {
  local sheldon_file="$ZDOTFILES_CONFIG_DIR/plugins.zsh"
  local backup_file="$sheldon_file.bak"
  
  # Create backup if it doesn't exist
  if [[ ! -f $backup_file ]]; then
    cp "$sheldon_file" "$backup_file"
    echo "Created backup of plugins.zsh at $backup_file"
  fi
  
  # Create a safer profiling version of sheldon loader
  cat > "$sheldon_file" << 'EOF'
# ===============================
# PLUGIN MANAGER: Sheldon (PROFILING VERSION)
# ===============================
if command -v sheldon &>/dev/null; then
  # Clear the log file
  SHELDON_PROFILE_LOG="/tmp/zsh_sheldon_profile.log"
  : > "$SHELDON_PROFILE_LOG"
  
  # Process output line by line safely
  sheldon source 2>/dev/null | while IFS= read -r line; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" == \#* ]] && continue
    
    # Try to determine the plugin name
    plugin_name="plugin-$RANDOM"
    
    if [[ "$line" == source* && "$line" == *\#* ]]; then
      # Extract from comment if available
      plugin_name=$(echo "$line" | sed -E 's/.*#[ \t]*([a-zA-Z0-9_-]+).*/\1/')
    elif [[ "$line" == source* ]]; then
      # Extract from path
      plugin_path=$(echo "$line" | sed -E 's/source[ \t]+"([^"]+)".*/\1/;s/source[ \t]+'"'"'([^'"'"']+)'"'"'.*/\1/')
      if [[ -n "$plugin_path" ]]; then
        plugin_name=$(basename "$plugin_path" | sed 's/\.[^.]*$//')
      fi
    elif [[ "$line" == eval* ]]; then
      # Attempt to get something meaningful from the eval
      plugin_name="eval-plugin-$RANDOM"
    fi
    
    # Measure plugin loading time
    time_start=$(($(date +%s%N)/1000000))
    
    # Evaluate the line safely - redirect errors to prevent parsing issues
    eval "$line" >/dev/null 2>&1
    
    time_end=$(($(date +%s%N)/1000000))
    time_elapsed=$((time_end-time_start))
    
    # Log the timing
    echo "plugin:$plugin_name:$time_elapsed" >> "$SHELDON_PROFILE_LOG"
  done
fi
EOF
}

# Restore the original modules.zsh file
restore_modules_file() {
  local modules_file="$ZDOTFILES_CONFIG_DIR/modules.zsh"
  local backup_file="$modules_file.bak"
  
  if [[ -f $backup_file ]]; then
    cp "$backup_file" "$modules_file"
    echo "Restored original modules.zsh file"
  else
    echo "No backup file found at $backup_file"
  fi
}

# Restore the original plugins.zsh file
restore_sheldon_file() {
  local sheldon_file="$ZDOTFILES_CONFIG_DIR/plugins.zsh"
  local backup_file="$sheldon_file.bak"
  
  if [[ -f $backup_file ]]; then
    cp "$backup_file" "$sheldon_file"
    echo "Restored original plugins.zsh file"
  else
    echo "No backup file found at $backup_file"
  fi
}

# Format milliseconds with color based on threshold (fixed version)
format_ms() {
  local ms=$1
  if (( ms < 5 )); then
    echo "${GREEN}${ms}ms${NC}"
  elif (( ms < 20 )); then
    echo "${YELLOW}${ms}ms${NC}"
  else
    echo "${RED}${ms}ms${NC}"
  fi
}

# Parse module profiling logs and display sorted by time
parse_module_logs() {
  if [[ ! -f "$ZDOTFILES_PROFILE_LOG" ]]; then
    echo "No module profiling log found"
    return
  fi

  local -A dir_times
  local -A file_times
  
  # Process log data, handling only valid numeric inputs
  while IFS=: read -r type dir_name file_name time_str; do
    # Make sure time is a valid number
    if [[ "$time_str" =~ ^[0-9]+$ ]]; then
      if [[ "$type" == "dir" && "$file_name" == "end" ]]; then
        dir_times[$dir_name]=$time_str
      elif [[ "$type" == "file" ]]; then
        file_times["$dir_name/$file_name"]=$time_str
      fi
    fi
  done < "$ZDOTFILES_PROFILE_LOG"
  
  # Display directory summaries
  echo "${BOLD}Module Directories Summary:${NC}"
  # Only proceed if there are valid entries
  if (( ${#dir_times} > 0 )); then
    for dir_name time in "${(@kv)dir_times}"; do
      printf "%-30s %s\n" "$dir_name" "$(format_ms $time)"
    done | sort -k2 -nr
  else
    echo "No valid directory timing data found"
  fi
  
  echo "\n${BOLD}Individual Files (Top 20, sorted by time):${NC}"
  # Only proceed if there are valid entries
  if (( ${#file_times} > 0 )); then
    for file_path time in "${(@kv)file_times}"; do
      printf "%-45s %s\n" "$file_path" "$(format_ms $time)"
    done | sort -k2 -nr | head -20
  else
    echo "No valid file timing data found"
  fi
}

# Parse sheldon plugin logs and display sorted by time
parse_sheldon_logs() {
  if [[ ! -f "$SHELDON_PROFILE_LOG" ]]; then
    echo "No Sheldon profiling log found"
    return
  fi

  local -A plugin_times
  
  # Process log data, handling only valid numeric inputs
  while IFS=: read -r type plugin_name time_str; do
    # Make sure time is a valid number
    if [[ "$type" == "plugin" && "$time_str" =~ ^[0-9]+$ ]]; then
      plugin_times[$plugin_name]=$time_str
    fi
  done < "$SHELDON_PROFILE_LOG"
  
  # Display plugin summaries
  echo "${BOLD}Sheldon Plugins (sorted by time):${NC}"
  # Only proceed if there are valid entries
  if (( ${#plugin_times} > 0 )); then
    for plugin_name time in "${(@kv)plugin_times}"; do
      printf "%-30s %s\n" "$plugin_name" "$(format_ms $time)"
    done | sort -k2 -nr
  else
    echo "No valid plugin timing data found"
  fi
}

# Generate recommendations based on profiling data
generate_recommendations() {
  local -a slow_plugins=()
  local -a slow_modules=()
  
  # Find slow plugins
  if [[ -f "$SHELDON_PROFILE_LOG" ]]; then
    while IFS=: read -r type plugin_name time_str; do
      if [[ "$type" == "plugin" && "$time_str" =~ ^[0-9]+$ && $time_str -gt 10 ]]; then
        slow_plugins+=("$plugin_name ($time_str ms)")
      fi
    done < "$SHELDON_PROFILE_LOG"
  fi
  
  # Find slow modules
  if [[ -f "$ZDOTFILES_PROFILE_LOG" ]]; then
    while IFS=: read -r type dir_name file_name time_str; do
      if [[ "$type" == "file" && "$time_str" =~ ^[0-9]+$ && $time_str -gt 10 ]]; then
        slow_modules+=("$dir_name/$file_name ($time_str ms)")
      fi
    done < "$ZDOTFILES_PROFILE_LOG"
  fi
  
  echo "${BOLD}Recommendations for Improvement:${NC}"
  
  # General recommendations
  echo "${BLUE}General optimizations:${NC}"
  echo "1. Use ${BOLD}sheldon inline lazy plugins${NC} for slow plugins:"
  echo "   Example:"
  echo "   [plugins.slow-plugin]"
  echo "   inline = '''"
  echo "   slow_command() {"
  echo "     unfunction slow_command"
  echo "     # Load actual implementation"
  echo "     eval \"\$(sheldon-original-command)\""
  echo "     slow_command \"\$@\""
  echo "   }"
  echo "   '''"
  echo "2. Consider using ${BOLD}fast-syntax-highlighting${NC} instead of zsh-syntax-highlighting"
  echo "3. Use ${BOLD}POWERLEVEL9K_INSTANT_PROMPT=quiet${NC} to avoid warnings"
  
  # Plugin-specific recommendations
  if (( ${#slow_plugins} > 0 )); then
    echo "\n${BLUE}Slow plugins to optimize:${NC}"
    for plugin in $slow_plugins; do
      echo "- Lazy-load $plugin"
    done
  fi
  
  # Module-specific recommendations
  if (( ${#slow_modules} > 0 )); then
    echo "\n${BLUE}Slow modules to optimize:${NC}"
    for module in $slow_modules; do
      echo "- Review $module"
    done
  fi
}

# Run interactive zsh with profiling
run_zsh_with_profiling() {
  # Run zsh with zprof loaded for overall profiling - safer version
  zsh -c '
    zmodload zsh/zprof
    # Redirect stderr to avoid polluting the output with errors
    source ~/.zshrc >/dev/null 2>&1 || true
    # Only show zprof output, no errors
    zprof -c 2>/dev/null || true
  ' > /tmp/zsh_zprof_output.log 2>/dev/null
  
  # Extract the top 15 time-consuming functions, safely
  if [[ -f /tmp/zsh_zprof_output.log ]]; then
    grep -v "total" /tmp/zsh_zprof_output.log 2>/dev/null | head -15 || echo "No profiling data available"
  else
    echo "Failed to generate profiling data"
  fi
}

# Start fresh zsh instance with profiling enabled
do_profiling() {
  # Clear all log files
  : > "$OVERALL_PROFILE_LOG"
  : > "$ZDOTFILES_PROFILE_LOG"
  : > "$SHELDON_PROFILE_LOG"
  
  # Setup profiling
  setup_module_profiling
  setup_sheldon_profiling
  
  echo "${BOLD}=== ZSH STARTUP PERFORMANCE ANALYSIS ===${NC}\n" | tee -a "$OVERALL_PROFILE_LOG"
  
  # Get system information
  echo "System: $(uname -rsm)" | tee -a "$OVERALL_PROFILE_LOG"
  echo "Shell: $SHELL ($(zsh --version))" | tee -a "$OVERALL_PROFILE_LOG"
  echo "Date: $(date)" | tee -a "$OVERALL_PROFILE_LOG"
  
  # Measure startup time
  echo "\n${BOLD}Overall Startup Time:${NC}" | tee -a "$OVERALL_PROFILE_LOG"
  (time (zsh -i -c exit)) 2>&1 | tee -a "$OVERALL_PROFILE_LOG"
  
  echo "\n${BOLD}=== STARTUP PHASES (zprof) ===${NC}\n" | tee -a "$OVERALL_PROFILE_LOG"
  run_zsh_with_profiling | tee -a "$OVERALL_PROFILE_LOG"
  
  echo "\n${BOLD}=== SHELDON PLUGIN ANALYSIS ===${NC}\n" | tee -a "$OVERALL_PROFILE_LOG"
  parse_sheldon_logs | tee -a "$OVERALL_PROFILE_LOG"
  
  echo "\n${BOLD}=== MODULE LOADING ANALYSIS ===${NC}\n" | tee -a "$OVERALL_PROFILE_LOG"
  parse_module_logs | tee -a "$OVERALL_PROFILE_LOG"
  
  echo "\n${BOLD}=== OPTIMIZATION RECOMMENDATIONS ===${NC}\n" | tee -a "$OVERALL_PROFILE_LOG"
  generate_recommendations | tee -a "$OVERALL_PROFILE_LOG"
  
  # Restore original files with confirmation to avoid accidental overwrites
  echo "${YELLOW}Restore original modules.zsh?${NC} (y/N) "
  read -q REPLY || echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    restore_modules_file
  else
    echo "Keeping profiling version of modules.zsh"
  fi
  
  echo "${YELLOW}Restore original plugins.zsh?${NC} (y/N) "
  read -q REPLY || echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    restore_sheldon_file
  else
    echo "Keeping profiling version of plugins.zsh"
  fi
  
  echo "\n${GREEN}Complete report saved to:${NC} $OVERALL_PROFILE_LOG"
}

# Run the profiling
do_profiling 