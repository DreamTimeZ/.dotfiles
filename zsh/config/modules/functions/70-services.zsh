# ===============================
# SERVICE MANAGEMENT FUNCTIONS
# ===============================

# Ollama AI service management
if zdotfiles_has_command ollama; then
    # Poll the API instead of guessing a fixed sleep; the server needs a moment
    # to bind before it accepts connections.
    zdotfiles_ollama_wait_ready() {
        local -r max_attempts=20        # up to 5s (20 x 0.25s) to accept connections
        local -r poll_interval=0.25
        local attempt
        for (( attempt = 1; attempt <= max_attempts; attempt++ )); do
            ollama ps >/dev/null 2>&1 && return 0
            sleep "$poll_interval"
        done
        return 1
    }

    # Wait for the serve process AND its runner subprocess (both named 'ollama')
    # to actually exit, escalating to SIGKILL, so a follow-up start never races
    # a still-dying server.
    zdotfiles_ollama_wait_stopped() {
        local -r max_attempts=20        # up to 5s for a graceful SIGTERM shutdown
        local -r poll_interval=0.25
        local attempt
        for (( attempt = 1; attempt <= max_attempts; attempt++ )); do
            pgrep -x ollama >/dev/null 2>&1 || return 0
            sleep "$poll_interval"
        done
        pkill -9 -x ollama 2>/dev/null
    }

    # Start Ollama service
    ollama-start() {
        if pgrep -x ollama >/dev/null; then
            echo "Ollama service already running"
            return 0
        fi

        # Persist stdout+stderr: a bare `ollama serve` writes only to its terminal,
        # so a crashed MLX runner leaves no trace once that terminal is gone.
        local log_file="${HOME}/.ollama/logs/server.log"
        mkdir -p "${log_file:h}"

        echo "Starting Ollama service..."
        # nohup + disown + </dev/null: fully detach so closing the launching terminal
        # cannot SIGHUP the server out from under a long-running model.
        nohup ollama serve >> "$log_file" 2>&1 </dev/null &
        disown

        if zdotfiles_ollama_wait_ready; then
            echo "Ollama service started (logs: $log_file)"
        else
            print -u2 "Ollama service failed to become ready; see $log_file"
            return 1
        fi
    }

    # Stop Ollama service
    ollama-stop() {
        if ! pgrep -x ollama >/dev/null; then
            echo "Ollama service not running"
            return 0
        fi

        echo "Stopping Ollama service..."
        pkill -x ollama
        zdotfiles_ollama_wait_stopped
        echo "Ollama service stopped"
    }

    # Restart Ollama service. Liveness checks report a wedged server as healthy,
    # so recovering an MLX-runner wedge (broken-pipe crash loop) needs a full cycle.
    ollama-restart() {
        ollama-stop
        ollama-start
    }

    # Check Ollama service status
    ollama-status() {
        if pgrep -x ollama >/dev/null; then
            echo "Running"
        else
            echo "Stopped"
        fi
    }
fi
