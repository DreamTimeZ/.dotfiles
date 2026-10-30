local config = require("modules.hotkeys.config")
local logging = require("modules.hotkeys.core.logging")
local actions = require("modules.hotkeys.core.actions")
local modals = require("modules.hotkeys.core.modals")

local systemModal = config.modals.system

local function shutdownSystem()
    logging.info("Shutdown requested, showing confirmation dialog")
    local button = hs.dialog.blockAlert(
        "Confirm Shutdown",
        "Are you sure you want to shut down your computer?",
        "Shutdown", "Cancel", "NSCriticalAlertStyle"
    )
    if button == "Shutdown" then
        logging.info("Shutdown confirmed, executing shutdown command")
        hs.execute("osascript -e 'tell app \"System Events\" to shut down'")
        return true
    else
        logging.info("Shutdown cancelled by user")
        return true
    end
end

local function restartSystem()
    logging.info("Restart requested, showing confirmation dialog")
    local button = hs.dialog.blockAlert(
        "Confirm Restart",
        "Are you sure you want to restart your computer?",
        "Restart", "Cancel", "NSCriticalAlertStyle"
    )
    if button == "Restart" then
        logging.info("Restart confirmed, executing restart command")
        hs.execute("osascript -e 'tell app \"System Events\" to restart'")
        return true
    else
        logging.info("Restart cancelled by user")
        return true
    end
end

local function reloadHammerspoon()
    logging.info("Reloading Hammerspoon configuration")
    hs.reload()
    return true
end

local naturalScroll = require("modules.hotkeys.macros.natural-scroll")

local function toggleNaturalScroll()
    logging.info("Toggling Natural Scroll")
    naturalScroll.toggle()
    return true
end

local function addNewDesktop()
    logging.info("Adding new desktop space")
    local ok, err = hs.spaces.addSpaceToScreen()
    if not ok then
        logging.error("Failed to add desktop space: " .. tostring(err))
        return false
    end
    return true
end

local systemMappings = {
    c = { action = actions.handlers.clearNotifications, desc = "Clear Notifications" },
    n = { action = toggleNaturalScroll, desc = "Toggle Natural Scroll" },
    s = { action = shutdownSystem, desc = "Shutdown System" },
    r = { action = restartSystem, desc = "Restart System" },
    h = { action = reloadHammerspoon, desc = "Reload Hammerspoon" },
    d = { action = addNewDesktop, desc = "New Desktop" },
}

systemModal.mappings = systemMappings

local modal = modals.createModalModule(
    systemMappings,
    systemModal.title,
    systemModal,
    "system"
)

return modal
