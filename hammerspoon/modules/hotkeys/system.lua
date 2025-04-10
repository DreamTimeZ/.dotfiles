-- Module for system actions (e.g., clear notifications).

local utils = require("modules.hotkeys.utils")
local modal = hs.hotkey.modal.new()
local M = {}

-- System actions with confirmation to prevent accidental triggers
local function shutdownSystem()
    local button, _ = hs.dialog.blockAlert("Confirm Shutdown", 
        "Are you sure you want to shut down your computer?", 
        "Shutdown", "Cancel", "NSCriticalAlertStyle")
    if button == "Shutdown" then
        hs.execute("osascript -e 'tell app \"System Events\" to shut down'")
    end
end

local function restartSystem()
    local button, _ = hs.dialog.blockAlert("Confirm Restart", 
        "Are you sure you want to restart your computer?", 
        "Restart", "Cancel", "NSCriticalAlertStyle")
    if button == "Restart" then
        hs.execute("osascript -e 'tell app \"System Events\" to restart'")
    end
end

local systemMapping = {
    c = { action = utils.clearNotifications, desc = "Clear Notifications" },
    s = { action = shutdownSystem, desc = "Shutdown System" },
    r = { action = restartSystem, desc = "Restart System" },
}

function modal:entered()
    hs.alert.closeAll()
    local hintParts = {"System Actions:"}
    for key, binding in pairs(systemMapping) do
        table.insert(hintParts, string.format("[%s] %s", key, binding.desc))
    end
    hs.alert.show(table.concat(hintParts, "  "))
end

for key, binding in pairs(systemMapping) do
    modal:bind("", key, function()
        binding.action()
        hs.alert.closeAll()
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