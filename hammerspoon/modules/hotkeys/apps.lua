-- Module for launching and focusing apps using a modal.

local utils = require("modules.hotkeys.utils")
local modal = hs.hotkey.modal.new()
local M = {}

-- Default application mappings (standard macOS apps)
local appsMapping = {
    a = { app = "App Store",             desc = "App Store" },
    b = { app = "Books",                 desc = "Books" },
    c = { app = "Calendar",              desc = "Calendar" },
    f = { app = "FaceTime",              desc = "FaceTime" },
    h = { app = "Photos",                desc = "Photos" },
    m = { app = "Mail",                  desc = "Mail" },
    n = { app = "Notes",                 desc = "Notes" },
    o = { app = "Maps",                  desc = "Maps" },
    p = { app = "Preview",               desc = "Preview" },
    r = { app = "Reminders",             desc = "Reminders" },
    s = { app = "Safari",                desc = "Safari" },
    t = { app = "Terminal",              desc = "Terminal" },
    u = { app = "Music",                 desc = "Music" },
    v = { app = "QuickTime Player",      desc = "QuickTime" },
    w = { app = "Weather",               desc = "Weather" },
    x = { app = "Calculator",            desc = "Calculator" },
    z = { app = "System Settings",       desc = "Settings" },
}

-- Load local mappings from local/apps_mappings.lua if it exists
-- If local mappings exist, they will completely replace the defaults
appsMapping = utils.loadLocalMappings(appsMapping, "modules.hotkeys.local.apps_mappings", "app")

function modal:entered()
    hs.alert.closeAll()  -- Clear any previous alerts
    local hintParts = {"Apps:"}
    for key, binding in pairs(appsMapping) do
        table.insert(hintParts, string.format("[%s] %s", key, binding.desc))
    end
    hs.alert.show(table.concat(hintParts, "  "))
end

for key, binding in pairs(appsMapping) do
    modal:bind("", key, function()
        utils.launchOrFocus(binding.app)
        hs.alert.closeAll()  -- Immediately clear the hint
        modal:exit()
    end)
end

modal:bind("", "escape", function() hs.alert.closeAll() modal:exit() end)

function M.enter()
    modal:enter()
end

function M.exit()
    modal:exit()
    hs.alert.closeAll()
end

return M