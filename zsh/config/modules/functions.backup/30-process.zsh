# ===============================
# INTERACTIVE PROCESS UTILITIES
# ===============================

# Only define interactive process functions if fzf is available
if zdotfiles_has_command fzf; then
    # Interactive process killer
    # Usage: fpkill [-9] [signal]
    fpkill() {
        local sig="TERM"
        [[ "$1" == "-9" ]] && sig="KILL" && shift
        [[ -n "$1" ]] && sig="$1"
        
        local pids
        pids=$(ps axo pid,ppid,user,%cpu,%mem,comm | 
               tail -n +2 |
               fzf -m --header="Kill with SIG$sig (TAB=multi)" \
                   --preview='ps -p {1} -o pid,ppid,user,start,time,command' \
                   --preview-window=right:50% |
               awk '{print $1}') || return
        
        [[ -n "$pids" ]] && {
            echo "Killing PIDs: $pids with SIG$sig"
            kill -s "$sig" $pids
        }
    }

    # Interactive shell history search
    # Usage: fh [-e] (execute command)
    fh() {
        local cmd
        cmd=$(fc -l 1 | fzf --tac --height=50% --reverse | 
              sed 's/^[[:space:]]*[0-9]*[[:space:]]*//')
        
        [[ -n "$cmd" ]] && {
            [[ "$1" == "-e" ]] && eval "$cmd" || print -z "$cmd"
        }
    }
fi 