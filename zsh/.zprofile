# ===============================
# ENVIRONMENT VARIABLES (Login-specific)
# ===============================

# Set PATH
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"

# Set default editor
export EDITOR=nvim

# ===============================
# SSH-Agent & SSH Keys (Login-specific)
# ===============================

# Start the SSH agent if not already running
if ! pgrep -x ssh-agent > /dev/null; then
    eval "$(ssh-agent -s)" > /dev/null
fi

# Get the list of already loaded keys
LOADED_KEYS=$(ssh-add -l 2>/dev/null | awk '{print $2}')

# Automatically add all SSH private keys if not already added
for key in ~/.ssh/*; do
    # Ensure it's a private key (not a .pub, config, or known_hosts files)
    if [[ -f "$key" && "$(basename "$key")" != *.pub && "$(basename "$key")" != config && "$(basename "$key")" != config.local && ! "$(basename "$key")" =~ ^known_hosts ]]; then
        # Get the key's fingerprint
        KEY_FINGERPRINT=$(ssh-keygen -lf "$key" | awk '{print $2}')
        
        # Check if the key is already loaded
        if ! echo "$LOADED_KEYS" | grep -q "$KEY_FINGERPRINT"; then
            ssh-add --apple-use-keychain "$key"
        fi
    fi
done