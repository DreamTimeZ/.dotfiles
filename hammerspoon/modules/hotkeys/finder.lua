-- Module for opening Finder folders.

local utils = require("modules.hotkeys.utils")
local modal = hs.hotkey.modal.new()
local M = {}

local finderMapping = {
    d = { path = os.getenv("HOME") .. "/Downloads",                 desc = "Downloads" },
    s = { path = os.getenv("HOME") .. "/Documents/Studies",           desc = "Studies" },
    p = { path = os.getenv("HOME") .. "/Documents/Studies/Audio/processed", desc = "Audio Processed" },
}

function modal:entered()
    hs.alert.closeAll()
    local hintParts = {"Finder Folders:"}
    for key, binding in pairs(finderMapping) do
        table.insert(hintParts, string.format("[%s] %s", key, binding.desc))
    end
    hs.alert.show(table.concat(hintParts, "  "))
end

for key, binding in pairs(finderMapping) do
    modal:bind("", key, function()
        utils.openFinderFolder(binding.path)
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