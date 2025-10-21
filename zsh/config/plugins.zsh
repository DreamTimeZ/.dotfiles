# ===============================
# PLUGIN MANAGER: Sheldon
# ===============================
if [[ -n $commands[sheldon] ]]; then
  eval "$(sheldon source 2>/dev/null)"
fi