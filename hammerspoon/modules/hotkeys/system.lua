-- Module for system actions (e.g., clear notifications, shutdown, etc.)
local utils = require("modules.hotkeys.utils")
local config = require("modules.hotkeys.config")

-- System actions with confirmation to prevent accidental triggers
local function shutdownSystem()
    utils.info("Shutdown requested, showing confirmation dialog")
    local button = hs.dialog.blockAlert(
        "Confirm Shutdown", 
        "Are you sure you want to shut down your computer?", 
        "Shutdown", "Cancel", "NSCriticalAlertStyle"
    )
    if button == "Shutdown" then
        utils.info("Shutdown confirmed, executing shutdown command")
        hs.execute("osascript -e 'tell app \"System Events\" to shut down'")
    else
        utils.info("Shutdown cancelled by user")
    end
    return true
end

local function restartSystem()
    utils.info("Restart requested, showing confirmation dialog")
    local button = hs.dialog.blockAlert(
        "Confirm Restart", 
        "Are you sure you want to restart your computer?", 
        "Restart", "Cancel", "NSCriticalAlertStyle"
    )
    if button == "Restart" then
        utils.info("Restart confirmed, executing restart command")
        hs.execute("osascript -e 'tell app \"System Events\" to restart'")
    else
        utils.info("Restart cancelled by user")
    end
    return true
end

local function reloadHammerspoon()
    utils.info("Reloading Hammerspoon configuration")
    hs.reload()
    return true
end

-- Define system actions mapping
local systemMapping = {
    c = { action = utils.clearNotifications, desc = "Clear Notifications" },
    s = { action = shutdownSystem, desc = "Shutdown System" },
    r = { action = restartSystem, desc = "Restart System" },
    h = { action = reloadHammerspoon, desc = "Reload Hammerspoon" },
}

-- Store the mapping in config for consistent definition
config.system = systemMapping

-- Get the system-specific modal definition
local systemDef = config.modalDefinitions.system

-- Create modal module with the system configuration
local modal = utils.createModalModule(
    systemMapping,
    systemDef.title,
    systemDef.type,
    "modules.hotkeys.local.system_mappings"
)

return modal