# ===============================
# SERVICE MANAGEMENT FUNCTIONS
# ===============================

# Ollama AI service management
if zdotfiles_has_command ollama; then
    # Start Ollama service
    ollama-start() {
        if ! pgrep -x ollama >/dev/null; then
            echo "Starting Ollama service..."
            ollama serve > /dev/null 2>&1 &
            sleep 2
            echo "Ollama service started"
        else
            echo "Ollama service already running"
        fi
    }
    
    # Stop Ollama service
    ollama-stop() {
        if pgrep -x ollama >/dev/null; then
            echo "Stopping Ollama service..."
            pkill -x ollama
            echo "Ollama service stopped"
        else
            echo "Ollama service not running"
        fi
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
