-- Module for launching and focusing apps using a modal.

local utils = require("modules.hotkeys.utils")
local modal = hs.hotkey.modal.new()
local M = {}

local appsMapping = {
    a = { app = "Obsidian",              desc = "Obsidian" },
    c = { app = "Cursor",                desc = "Cursor" },
    d = { app = "Discord",               desc = "Discord" },
    e = { app = "Microsoft Excel",       desc = "Excel" },
    f = { app = "Firefox",               desc = "Firefox" },
    g = { app = "ChatGPT",               desc = "ChatGPT" },
    i = { app = "Microsoft PowerPoint",  desc = "PowerPoint" },
    k = { app = "Docker",                desc = "Docker" },
    l = { app = "Slack",                 desc = "Slack" },
    m = { app = "Mullvad VPN",           desc = "Mullvad" },
    o = { app = "Microsoft Outlook",     desc = "Outlook" },
    p = { app = "App Store",             desc = "App Store" },
    r = { app = "Trello",                desc = "Trello" },
    s = { app = "Spotify",               desc = "Spotify" },
    t = { app = "Microsoft Teams",       desc = "Teams" },
    w = { app = "WhatsApp",              desc = "WhatsApp" },
    y = { app = "Microsoft Word",        desc = "Word" },
}

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