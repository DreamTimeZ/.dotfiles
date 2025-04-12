-- Module for system actions (e.g., clear notifications, shutdown, etc.)

local utils = require("modules.hotkeys.utils")
local config = require("modules.hotkeys.config")
local M = {}

-- System actions with confirmation to prevent accidental triggers
local function shutdownSystem()
    local button = hs.dialog.blockAlert(
        "Confirm Shutdown", 
        "Are you sure you want to shut down your computer?", 
        "Shutdown", "Cancel", "NSCriticalAlertStyle"
    )
    if button == "Shutdown" then
        hs.execute("osascript -e 'tell app \"System Events\" to shut down'")
    end
end

local function restartSystem()
    local button = hs.dialog.blockAlert(
        "Confirm Restart", 
        "Are you sure you want to restart your computer?", 
        "Restart", "Cancel", "NSCriticalAlertStyle"
    )
    if button == "Restart" then
        hs.execute("osascript -e 'tell app \"System Events\" to restart'")
    end
end

local function reloadHammerspoon()
    utils.debug("Reloading Hammerspoon configuration")
    hs.alert.closeAll()
    utils.showFormattedAlert("Reloading Hammerspoon...")
    hs.timer.doAfter(0.5, hs.reload)
end

-- Define system actions mapping
local systemMapping = {
    c = { action = utils.clearNotifications, desc = "Clear Notifications" },
    s = { action = shutdownSystem, desc = "Shutdown System" },
    r = { action = restartSystem, desc = "Restart System" },
    h = { action = reloadHammerspoon, desc = "Reload Hammerspoon" },
}

-- Load local mappings if they exist
systemMapping = utils.loadMappings(systemMapping, "modules.hotkeys.local.system_mappings", "fn")

-- Create modal with the system configuration
local modal = utils.setupModal(systemMapping, "System Actions:", "fn")

-- Public API
function M.enter()
    modal:enter()
end

function M.exit()
    modal:exit()
    hs.alert.closeAll()
end

return M