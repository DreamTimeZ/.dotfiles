-- Module for launching websites.

local utils = require("modules.hotkeys.utils")
local modal = hs.hotkey.modal.new()
local M = {}

local websitesMapping = {
    o = { url = "https://onedrive.live.com/",    desc = "OneDrive Live" },
    g = { url = "https://github.com/",           desc = "GitHub" },
    d = { url = "https://www.deepl.com/",        desc = "DeepL" },
    y = { url = "https://www.youtube.com/",      desc = "YouTube" },
}

function modal:entered()
    hs.alert.closeAll()
    local hintParts = {"Websites:"}
    for key, binding in pairs(websitesMapping) do
        table.insert(hintParts, string.format("[%s] %s", key, binding.desc))
    end
    hs.alert.show(table.concat(hintParts, "  "))
end

for key, binding in pairs(websitesMapping) do
    modal:bind("", key, function()
        utils.openURL(binding.url)
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