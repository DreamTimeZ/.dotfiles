-- Macro mappings configuration
-- This file defines the hotkey mappings for the macros modal
-- Access via Hyper + M, then the key below

return {
    -- Macro toggles (action names auto-generated as "toggle" .. registry-name)
    a = {
        action = "toggleAutoClicker",
        desc = "Toggle Auto-Clicker"
    },
    r = {
        action = "toggleRecording",
        desc = "Toggle Recording"
    },

    -- Utility actions
    s = {
        action = "stopAll",
        desc = "Stop All Macros"
    },

    -- Status of all macros
    i = {
        action = "showStatus",
        desc = "Show Macro Status"
    }
}
