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

-- HOW TO ADD A NEW MODAL:
-- Just add a new entry to config.modals with the following structure:
--
-- config.modals.newmodal = {
--     title = "My New Modal:",  -- Title to display in the modal
--     handler = {
--         field = "myfield",    -- Field name required in mappings
--         action = "myHandler"  -- Function in utils to handle the action
--     },
--     mappings = {              -- Key mappings for this modal
--         a = { myfield = "value1", desc = "Description 1" },
--         b = { myfield = "value2", desc = "Description 2" }
--     },
--     -- Optional for custom implementations:
--     customModule = "modules.hotkeys.mymodule"
-- }
--
-- The system will automatically handle your new modal without any code changes.

-- Modal definitions with their mappings
config.modals = {
    -- Applications modal
    apps = {
        title = "Apps:",
        handler = {
            field = "app",
            action = "launchOrFocus"
        },
        mappings = {
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
            z = { app = "System Settings",       desc = "Settings" }
        }
    },
    
    -- Finder locations modal
    finder = {
        title = "Finder:",
        handler = {
            field = "path",
            action = "openFinderFolder"
        },
        mappings = {
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
            i = { path = "~/Library/CloudStorage/iCloud Drive", desc = "iCloud" }
        }
    },
    
    -- Websites modal
    websites = {
        title = "Websites:",
        handler = {
            field = "url",
            action = "openURL"
        },
        mappings = {
            a = { url = "https://www.apple.com",         desc = "Apple" },
            g = { url = "https://github.com",            desc = "GitHub" },
            m = { url = "https://maps.google.com",       desc = "Maps" },
            n = { url = "https://www.netflix.com",       desc = "Netflix" },
            r = { url = "https://www.reddit.com",        desc = "Reddit" },
            s = { url = "https://www.stackoverflow.com", desc = "Stack Overflow" },
            w = { url = "https://www.wikipedia.org",     desc = "Wikipedia" },
            y = { url = "https://www.youtube.com",       desc = "YouTube" }
        }
    },
    
    -- System Settings panes modal
    settings = {
        title = "Settings:",
        handler = {
            field = "pref",
            action = "openSystemPreferencePane"
        },
        mappings = {
            u = { pref = "x-apple.systempreferences:com.apple.preferences.softwareupdate",    desc = "Software Update" },
            d = { pref = "x-apple.systempreferences:com.apple.preference.displays",           desc = "Displays" },
            p = { pref = "x-apple.systempreferences:com.apple.preference.security",           desc = "Privacy/Accessibility" },
            w = { pref = "x-apple.systempreferences:com.apple.preference.network",            desc = "Wi‑Fi" },
            b = { pref = "x-apple.systempreferences:com.apple.preferences.Bluetooth",         desc = "Bluetooth" }
        }
    },
    
    -- System actions modal
    system = {
        title = "System Actions:",
        handler = {
            field = "action",
            action = "functionCall"
        },
        customModule = "modules.hotkeys.modals.system"
        -- mappings defined in system.lua
    }
}

-- Global shortcuts configuration
config.globalShortcuts = {
    -- Modal activators
    { key = "a", modal = "apps",     desc = "Apps Modal" },
    { key = "f", modal = "finder",   desc = "Finder Modal" },
    { key = "w", modal = "websites", desc = "Websites Modal" },
    { key = "d", modal = "system",   desc = "System Modal" },
    { key = "s", modal = "settings", desc = "Settings Modal" },
    
    -- Direct app shortcuts
    { 
        key = "return", 
        handler = {
            field = "app",
            action = "launchOrFocus"
        },
        mapping = { app = "iTerm", desc = "Launch iTerm" }
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
local function getLocalModulePath(modalName)
    return config.paths.localModulesBase .. modalName .. "_mappings"
end

-- Safely require a module with error handling
local function safeRequire(modulePath, logFn)
    local status, result = pcall(require, modulePath)
    
    if status and type(result) == "table" then
        return result
    elseif logFn then
        if not status then
            logFn("Failed to load module " .. modulePath .. ": " .. tostring(result))
        else
            logFn("Module " .. modulePath .. " did not return a valid table")
        end
    end
    
    return nil
end

-- Load local configurations
function config.loadLocalConfigs(forceReload, utils)
    -- Skip if already initialized and not forcing reload
    if configCache.isInitialized and not forceReload then return end
    
    if utils then utils.info("Loading local configurations" .. (forceReload and " (forced)" or "")) end
    
    -- Load local mappings for all defined modals
    for modalName, modal in pairs(config.modals) do
        -- Skip if we've already loaded this modal's mappings and not forcing reload
        if not forceReload and configCache.localMappingsLoaded[modalName] then goto continue end
        
        -- Only try to load local mappings if this isn't a custom implementation
        if not modal.customModule then
            local localPath = getLocalModulePath(modalName)
            
            -- Load the local mappings
            local localMappings = safeRequire(localPath, utils and utils.debug)
            
            -- If local mappings loaded successfully, replace the defaults
            if localMappings and next(localMappings) ~= nil then
                if utils then utils.info("Using local mappings for " .. modalName) end
                modal.mappings = localMappings
            end
        end
        
        configCache.localMappingsLoaded[modalName] = true
        
        ::continue::
    end
    
    -- Load custom global shortcuts if available
    local localGlobalShortcuts = safeRequire(getLocalModulePath("global_shortcuts"), 
                                             utils and utils.debug)
    
    if localGlobalShortcuts and next(localGlobalShortcuts) ~= nil then
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
    for modalName, _ in pairs(config.modals) do
        package.loaded[getLocalModulePath(modalName)] = nil
    end
    
    -- Clear global shortcuts module from cache
    package.loaded[getLocalModulePath("global_shortcuts")] = nil
    
    -- Reset cache state
    configCache.isInitialized = false
    configCache.localMappingsLoaded = {}
    
    -- Reload all configurations
    config.loadLocalConfigs(true, utils)
    
    if utils then utils.info("Configuration reload complete") end
end

return config 