-- Module for opening Finder folders.

local utils = require("modules.hotkeys.utils")
local modal = hs.hotkey.modal.new()
local M = {}

-- Default finder mappings (standard macOS directories)
local finderMapping = {
    a = { path = os.getenv("HOME") .. "/Applications",  desc = "Applications" },
    d = { path = os.getenv("HOME") .. "/Desktop",       desc = "Desktop" },
    o = { path = os.getenv("HOME") .. "/Documents",     desc = "Documents" },
    w = { path = os.getenv("HOME") .. "/Downloads",     desc = "Downloads" },
    m = { path = os.getenv("HOME") .. "/Movies",        desc = "Movies" },
    u = { path = os.getenv("HOME") .. "/Music",         desc = "Music" },
    p = { path = os.getenv("HOME") .. "/Pictures",      desc = "Pictures" },
    h = { path = os.getenv("HOME"),                    desc = "Home" },
}

-- Load local mappings from local/finder_mappings.lua if it exists
-- If local mappings exist, they will completely replace the defaults
finderMapping = utils.loadLocalMappings(finderMapping, "modules.hotkeys.local.finder_mappings", "finder")

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