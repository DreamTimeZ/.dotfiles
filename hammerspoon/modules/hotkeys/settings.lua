-- Module for opening System Preferences panes using a URL‑based approach.

local utils = require("modules.hotkeys.utils")
local modal = hs.hotkey.modal.new()
local M = {}

local settingsMapping = {
    u = { url = "x-apple.systempreferences:com.apple.preferences.softwareupdate",    desc = "Software Update" },
    d = { url = "x-apple.systempreferences:com.apple.preference.displays",           desc = "Displays/Arrange" },
    p = { url = "x-apple.systempreferences:com.apple.preference.security",           desc = "Privacy/Accessibility" },
    w = { url = "x-apple.systempreferences:com.apple.preference.network",            desc = "Wi‑Fi" },
    b = { url = "x-apple.systempreferences:com.apple.preferences.Bluetooth",         desc = "Bluetooth" },
}

function modal:entered()
    hs.alert.closeAll()
    local hintParts = {"Settings:"}
    for key, binding in pairs(settingsMapping) do
        table.insert(hintParts, string.format("[%s] %s", key, binding.desc))
    end
    hs.alert.show(table.concat(hintParts, "  "))
end

for key, binding in pairs(settingsMapping) do
    modal:bind("", key, function()
        utils.openSystemPreferencePane(binding.url)
        hs.alert.closeAll()
        modal:exit()
    end)
end

modal:bind("", "escape", function()
    hs.alert.closeAll()
    modal:exit()
end)

function M.enter()
    modal:enter()
end

function M.exit()
    modal:exit()
    hs.alert.closeAll()
end

return M