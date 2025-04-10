-- Master module for all hotkey-related functionality.
-- Defines a table of hotkey modules and a function to exit any active modal.

-- The Hyper modifier (remapped Caps Lock (via karabiner-elements) to {"cmd", "ctrl", "alt", "shift"}) is used.
local hyper = {"cmd", "ctrl", "alt", "shift"}

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
    for _, mod in ipairs(hotkeyModules) do
        if mod.exit then
            mod.exit()
        end
    end
    hs.alert.closeAll()
end

-- Global hotkeys. Before opening a category, exit any currently active modal.
hs.hotkey.bind(hyper, "a", function()
    exitAllModals()
    apps.enter()
end)

hs.hotkey.bind(hyper, "f", function()
    exitAllModals()
    finder.enter()
end)

hs.hotkey.bind(hyper, "w", function()
    exitAllModals()
    websites.enter()
end)

hs.hotkey.bind(hyper, "n", function()
    exitAllModals()
    system.enter()
end)

hs.hotkey.bind(hyper, "s", function()
    exitAllModals()
    settings.enter()
end)

-- Additional Global Binding: iTerm2 (Hyper + Return)
local utils = require("modules.hotkeys.utils")
hs.hotkey.bind(hyper, "return", function()
    exitAllModals()
    utils.launchOrFocus("iTerm")
end)

hs.alert.show("Hotkeys Module Loaded")
