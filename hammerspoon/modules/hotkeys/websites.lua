-- Module for launching websites.

local utils = require("modules.hotkeys.utils")
local modal = hs.hotkey.modal.new()
local M = {}

-- Default website mappings (common websites)
local websitesMapping = {
    a = { url = "https://www.apple.com/",             desc = "Apple" },
    g = { url = "https://www.google.com/",            desc = "Google" },
    m = { url = "https://www.google.com/maps",        desc = "Google Maps" },
    n = { url = "https://www.netflix.com/",           desc = "Netflix" },
    r = { url = "https://www.reddit.com/",            desc = "Reddit" },
    t = { url = "https://translate.google.com/",      desc = "Translate" },
    w = { url = "https://en.wikipedia.org/",          desc = "Wikipedia" },
    y = { url = "https://www.youtube.com/",           desc = "YouTube" },
}

-- Load local mappings from local/websites_mappings.lua if it exists
-- If local mappings exist, they will completely replace the defaults
websitesMapping = utils.loadLocalMappings(websitesMapping, "modules.hotkeys.local.websites_mappings", "website")

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