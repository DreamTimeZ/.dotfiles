-- Module for system actions (e.g., clear notifications).

local utils = require("modules.hotkeys.utils")
local modal = hs.hotkey.modal.new()
local M = {}

local systemMapping = {
    c = { action = utils.clearNotifications, desc = "Clear Notifications" },
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