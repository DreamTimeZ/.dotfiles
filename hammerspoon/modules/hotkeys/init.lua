-- Master module for all hotkey-related functionality.
-- Uses centralized configuration and utility functions for better maintainability

-- Load configuration and utility modules
local config = require("modules.hotkeys.config")
local utils = require("modules.hotkeys.utils")

-- Initialize debug mode if needed
utils.setDebug(config.debug)
utils.debug("Initializing hotkeys module")

-- Load all config settings from local configurations if available
config.loadLocalConfigs()

-- Load sub-modules that define modals
local modules = {
    apps = require("modules.hotkeys.apps"),
    finder = require("modules.hotkeys.finder"),
    websites = require("modules.hotkeys.websites"),
    system = require("modules.hotkeys.system"),
    settings = require("modules.hotkeys.settings")
}

-- Function to exit all active modals and clear any alerts
local function exitAllModals()
    utils.debug("Exiting all modals")
    for _, mod in pairs(modules) do
        if mod.exit then mod.exit() end
    end
    hs.alert.closeAll()
end

-- Set up global hotkeys from config
for _, shortcut in ipairs(config.globalShortcuts) do
    if shortcut.action and modules[shortcut.action] then
        -- Modal activator
        hs.hotkey.bind(config.modifiers.hyper, shortcut.key, function()
            utils.debug("Activating " .. shortcut.action .. " modal")
            exitAllModals()
            modules[shortcut.action].enter()
        end)
    elseif shortcut.fn then
        -- Direct function call
        hs.hotkey.bind(config.modifiers.hyper, shortcut.key, function()
            utils.debug("Executing shortcut: " .. (shortcut.desc or shortcut.key))
            exitAllModals()
            shortcut.fn()
        end)
    end
end

utils.debug("Hotkeys module fully initialized")

-- Return the module API
return {
    exitAllModals = exitAllModals,
    setDebug = utils.setDebug,
    config = config
}
