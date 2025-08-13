# ===============================
# COLORIZED OUTPUT CONFIGURATION
# ===============================

# GRC (Generic Colorizer) setup
if zdotfiles_has_command grc; then
    # Commands to colorize
    typeset -a grc_commands=(
        ip ifconfig ping traceroute dig whois df du mount ps lsof
        netstat ss id vmstat iostat free
    )
    
    # Apply colorization to available commands
    for cmd in $grc_commands; do
        if zdotfiles_has_command "$cmd"; then
            alias "$cmd"="grc $cmd"
        fi
    done
    
    # Cleanup
    unset grc_commands
fi
