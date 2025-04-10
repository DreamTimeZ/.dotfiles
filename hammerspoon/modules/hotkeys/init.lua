-- Master module for all hotkey-related functionality.
-- Defines a table of hotkey modules and a function to exit any active modal.

-- The Hyper modifier (remapped Caps Lock (via karabiner-elements) to {"cmd", "ctrl", "alt", "shift"}) is used.
local hyper = {"cmd", "ctrl", "alt", "shift"}

-- Load utility module first to enable debug functionality
local utils = require("modules.hotkeys.utils")

-- Enable debug mode if needed (uncomment to activate)
-- utils.setDebug(true)
utils.debug("Initializing hotkeys module")

-- Load sub-modules in the hotkeys folder:
local apps = require("modules.hotkeys.apps")
local finder = require("modules.hotkeys.finder")
local websites = require("modules.hotkeys.websites")
local system = require("modules.hotkeys.system")
local settings = require("modules.hotkeys.settings")

-- For organization, list all modules that define a modal.
local hotkeyModules = {apps, finder, websites, system, settings}

-- Function to exit all active modals and clear any alerts.
local function exitAllModals()
    utils.debug("Exiting all modals")
    for _, mod in ipairs(hotkeyModules) do
        if mod.exit then
            mod.exit()
        end
    end
    hs.alert.closeAll()
end

-- Global hotkeys. Before opening a category, exit any currently active modal.
hs.hotkey.bind(hyper, "a", function()
    utils.debug("Activating apps modal")
    exitAllModals()
    apps.enter()
end)

hs.hotkey.bind(hyper, "f", function()
    utils.debug("Activating finder modal")
    exitAllModals()
    finder.enter()
end)

hs.hotkey.bind(hyper, "w", function()
    utils.debug("Activating websites modal")
    exitAllModals()
    websites.enter()
end)

hs.hotkey.bind(hyper, "n", function()
    utils.debug("Activating system modal")
    exitAllModals()
    system.enter()
end)

hs.hotkey.bind(hyper, "s", function()
    utils.debug("Activating settings modal")
    exitAllModals()
    settings.enter()
end)

-- Additional Global Binding: iTerm2 (Hyper + Return)
hs.hotkey.bind(hyper, "return", function()
    utils.debug("Activating iTerm")
    exitAllModals()
    utils.launchOrFocus("iTerm")
end)

hs.alert.show("Hotkeys Module Loaded")
utils.debug("Hotkeys module fully initialized")

-- Return the module API
return {
    exitAllModals = exitAllModals,
    setDebug = utils.setDebug
}
