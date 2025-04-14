-- Centralized configuration for hotkeys module
local config = {}

-- Base configuration settings
------------------------------

-- Paths configuration
config.paths = {
    localModulesBase = "modules.hotkeys.local.",  -- Base path for local modules
}

-- Modifier keys configuration
config.modifiers = {
    hyper = {"cmd", "ctrl", "alt", "shift"}
}

-- Logging configuration
config.logging = {
    -- Log levels
    LEVELS = {
        ERROR = 1,
        WARN = 2,
        INFO = 3,
        DEBUG = 4
    },
    -- Default settings
    enabled = true,
    level = 1,  -- Default to ERROR only
    -- Level name lookup
    levelNames = {
        [1] = "ERROR",
        [2] = "WARN",
        [3] = "INFO",
        [4] = "DEBUG"
    }
}

-- Timing constants
config.delays = {
    appActivation = 0.1,     -- Delay after launching app to ensure it's ready for activation
}

-- UI settings
config.ui = {
    maxItemsPerLine = 5,     -- Maximum items per line in formatted alerts
    keyFormat = "[%s] %s",   -- Format for key hint display
}

-- System preferences settings
config.systemPreferences = {
    checkInterval = 0.1,    -- How often to check if System Settings/Preferences has closed (seconds)
    maxWaitTime = 3.0,      -- Maximum time to wait for graceful close (seconds)
    forceKillDelay = 0.5,   -- Delay after force kill before opening a new URL (seconds)
}

-- Modal definitions - defines all available modals and their configuration
-- To add a new modal, just add a new entry to this table and create a mapping table
config.modalDefinitions = {
    apps = {
        title = "Apps:",
        type = "app",        -- Field name used in mappings
        mappingName = "apps", -- Config table containing mappings
        hasCustomImpl = false -- Whether this module has custom implementation
    },
    finder = {
        title = "Finder:",
        type = "path",
        mappingName = "finder",
        hasCustomImpl = false
    },
    websites = {
        title = "Websites:",
        type = "url",
        mappingName = "websites",
        hasCustomImpl = false
    },
    settings = {
        title = "Settings:",
        type = "pref",
        mappingName = "settings",
        hasCustomImpl = false
    },
    system = {
        title = "System Actions:",
        type = "fn",
        mappingName = "system",
        hasCustomImpl = true,  -- system.lua has a custom implementation
        customModule = "modules.hotkeys.system"
    }
    -- To add a new modal type, just add a new entry here
    -- Example:
    -- newmodal = {
    --    title = "New Modal:",
    --    type = "newtype",     -- Field name used for validation
    --    mappingName = "newmappings",
    --    hasCustomImpl = false
    -- }
}

-- Default mappings
------------------------------

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
        fn = function() 
            -- We'll call the utility function in init.lua to avoid circular dependency
            local appName = "iTerm"
            hs.application.launchOrFocus(appName)
            hs.timer.doAfter(config.delays.appActivation, function()
                local app = hs.application.get(appName)
                if app then app:activate() end
            end)
        end,
        desc = "Launch iTerm" 
    }
}

-- Configuration loading logic
------------------------------

-- Configuration cache to avoid repeated reloading
local configCache = {
    isInitialized = false,
    localMappingsLoaded = {}
}

-- Get the module path for a given module name
local function getLocalModulePath(moduleName)
    return config.paths.localModulesBase .. moduleName .. "_mappings"
end

-- Load local configurations
function config.loadLocalConfigs(forceReload, utils)
    -- Skip if already initialized and not forcing reload
    if configCache.isInitialized and not forceReload then return end
    
    if utils then utils.info("Loading local configurations" .. (forceReload and " (forced)" or "")) end
    
    -- Load local mappings for all module types defined in modalDefinitions
    for moduleName, modalDef in pairs(config.modalDefinitions) do
        -- Check if the modal definition has a type field
        if not modalDef.type then 
            if utils then utils.warn("No type defined for module: " .. moduleName) end
            goto continue 
        end
        
        -- Check if we need to reload this mapping
        if forceReload or not configCache.localMappingsLoaded[moduleName] then
            local localPath = getLocalModulePath(moduleName)
            
            -- Load the mappings using utils or fallback
            if utils then
                config[modalDef.mappingName] = utils.loadMappings(config[modalDef.mappingName], localPath, modalDef.type)
            else
                local status, localMappings = pcall(require, localPath)
                if status and type(localMappings) == "table" then
                    config[modalDef.mappingName] = localMappings
                end
            end
            configCache.localMappingsLoaded[moduleName] = true
        end
        
        ::continue::
    end
    
    -- Load custom global shortcuts if available
    local status, localGlobalShortcuts = pcall(require, getLocalModulePath("global_shortcuts"))
    if status and type(localGlobalShortcuts) == "table" and next(localGlobalShortcuts) ~= nil then
        if utils then utils.info("Using local global shortcuts configuration") end
        config.globalShortcuts = localGlobalShortcuts
    end
    
    configCache.isInitialized = true
    if utils then utils.info("Configuration loading complete") end
end

-- Force reload of configuration files
function config.reloadConfigs(utils)
    if utils then utils.info("Forcing configuration reload") end
    
    -- Clear package.loaded cache for all module mappings
    for moduleName, _ in pairs(config.modalDefinitions) do
        package.loaded[getLocalModulePath(moduleName)] = nil
    end
    
    -- Also clear global shortcuts
    package.loaded[getLocalModulePath("global_shortcuts")] = nil
    
    -- Reset cache
    configCache.isInitialized = false
    configCache.localMappingsLoaded = {}
    
    -- Reload configurations
    config.loadLocalConfigs(true, utils)
end

return config 