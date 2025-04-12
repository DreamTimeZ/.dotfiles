-- Centralized configuration for hotkeys module
local utils = require("modules.hotkeys.utils")
local config = {}

-- Modifier keys configuration
config.modifiers = {
    hyper = {"cmd", "ctrl", "alt", "shift"}
}

-- Debug settings
config.debug = false

-- Default application mappings
config.apps = {
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

-- Default finder locations
config.finder = {
    a = { path = "~/Applications",           desc = "Applications" },
    d = { path = "~/Desktop",                desc = "Desktop" },
    c = { path = "~/Documents",              desc = "Documents" },
    f = { path = "~/Downloads",              desc = "Downloads" },
    h = { path = "~/",                       desc = "Home" },
    p = { path = "~/Pictures",               desc = "Pictures" },
    m = { path = "~/Music",                  desc = "Music" },
    v = { path = "~/Movies",                 desc = "Movies" },
    l = { path = "~/Library",                desc = "Library" },
    u = { path = "/Utilities",               desc = "Utilities" },
    i = { path = "~/Library/CloudStorage/iCloud Drive", desc = "iCloud" },
}

-- Default website mappings
config.websites = {
    a = { url = "https://www.apple.com",         desc = "Apple" },
    g = { url = "https://github.com",            desc = "GitHub" },
    m = { url = "https://maps.google.com",       desc = "Maps" },
    n = { url = "https://www.netflix.com",       desc = "Netflix" },
    r = { url = "https://www.reddit.com",        desc = "Reddit" },
    s = { url = "https://www.stackoverflow.com", desc = "Stack Overflow" },
    w = { url = "https://www.wikipedia.org",     desc = "Wikipedia" },
    y = { url = "https://www.youtube.com",       desc = "YouTube" },
}

-- System preferences panes
config.settings = {
    u = { pref = "x-apple.systempreferences:com.apple.preferences.softwareupdate",    desc = "Software Update" },
    d = { pref = "x-apple.systempreferences:com.apple.preference.displays",           desc = "Displays" },
    p = { pref = "x-apple.systempreferences:com.apple.preference.security",           desc = "Privacy/Accessibility" },
    w = { pref = "x-apple.systempreferences:com.apple.preference.network",            desc = "Wi‑Fi" },
    b = { pref = "x-apple.systempreferences:com.apple.preferences.Bluetooth",         desc = "Bluetooth" },
}

-- Global shortcuts configuration
config.globalShortcuts = {
    -- Modal activators
    { key = "a", action = "apps",     desc = "Apps Modal" },
    { key = "f", action = "finder",   desc = "Finder Modal" },
    { key = "w", action = "websites", desc = "Websites Modal" },
    { key = "d", action = "system",   desc = "System Modal" },
    { key = "s", action = "settings", desc = "Settings Modal" },
    
    -- Direct app shortcuts
    { 
        key = "return", 
        fn = function() utils.launchOrFocus("iTerm") end,
        desc = "Launch iTerm" 
    },
    
    -- Reload Hammerspoon shortcut
    {
        key = "r",
        fn = function()
            utils.debug("Direct shortcut for reloading Hammerspoon")
            -- Activate system modal and press 'h' for reload
            hs.timer.doAfter(0.1, function()
                hs.eventtap.keyStroke({}, "h")
            end)
        end,
        desc = "Reload Hammerspoon"
    }
}

-- Load local configurations
function config.loadLocalConfigs()
    -- Load local mappings for all types
    config.apps = utils.loadMappings(config.apps, "modules.hotkeys.local.apps_mappings", "app")
    config.finder = utils.loadMappings(config.finder, "modules.hotkeys.local.finder_mappings", "path")
    config.websites = utils.loadMappings(config.websites, "modules.hotkeys.local.websites_mappings", "url")
    config.settings = utils.loadMappings(config.settings, "modules.hotkeys.local.settings_mappings", "pref")
    
    -- Optional: Load custom global shortcuts if available
    local status, localGlobalShortcuts = pcall(require, "modules.hotkeys.local.global_shortcuts")
    if status and type(localGlobalShortcuts) == "table" and next(localGlobalShortcuts) ~= nil then
        utils.debug("Using local global shortcuts configuration")
        config.globalShortcuts = localGlobalShortcuts
    end
end

return config 