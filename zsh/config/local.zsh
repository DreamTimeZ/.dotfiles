# ===============================
# LOCAL OVERRIDES LOADER
# ===============================
# Loads machine-specific configurations from modules/local/
# This file is sourced LAST in the config chain, so local files
# can override any previously defined settings (exports, keybindings, aliases, etc.)

for _local_file in "$ZDOTFILES_MODULES_DIR/local"/*.zsh(N-on); do
    source "$_local_file" 2>/dev/null
done
unset _local_file
