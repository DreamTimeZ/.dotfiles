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

    # Apply colorization only to available commands
    # Uses raw $commands hash in loop (avoids function call overhead for ~15 checks)
    for cmd in $grc_commands; do
        [[ -n $commands[$cmd] ]] && alias "$cmd"="grc $cmd"
    done

    # Cleanup
    unset grc_commands cmd
fi
