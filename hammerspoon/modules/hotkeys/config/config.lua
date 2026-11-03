local config = {}

config.paths = {
    localModulesBase = "modules.hotkeys.config.local.",
}

config.modifiers = {
    hyper = {"cmd", "ctrl", "alt", "shift"}
}

config.logging = {
    LEVELS = {
        ERROR = 1,
        WARN = 2,
        INFO = 3,
        DEBUG = 4
    },
    enabled = true,
    level = 1,
    maxMessageLength = 500, -- Prevent log spam
    rateLimiting = {
        enabled = true,
        maxPerSecond = 10,
        windowMs = 1000
    },
    includeTimestamp = true,
    includeLevel = true,
    includeContext = false,
    levelNames = {
        [1] = "ERROR",
        [2] = "WARN",
        [3] = "INFO",
        [4] = "DEBUG"
    }
}

config.delays = {
    appActivation = 0.1, -- Delay after launching app to ensure it's ready for activation
    ghosttyLaunchPoll = 0.1,
    ghosttyLaunchMaxAttempts = 30,
}

config.ui = {
    maxItemsPerLine = 5,
    keyFormat = "[%s] %s",
}

config.systemPreferences = {
    forceKillDelay = 0.5,
}

config.modals = {
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

    window = {
        title = "Window Management:",
        handler = {
            field = "action",
            action = "functionCall"
        },
        customModule = "modules.hotkeys.modals.window"
    },

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
            u = { path = "/System/Applications/Utilities", desc = "Utilities" },
            i = { path = "~/Library/Mobile Documents/com~apple~CloudDocs", desc = "iCloud" }
        }
    },

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

    settings = {
        title = "Settings:",
        handler = {
            field = "pref",
            action = "openSystemPreferencePane"
        },
        mappings = {
            u = { pref = "x-apple.systempreferences:com.apple.preferences.softwareupdate",    desc = "Software Update" },
            d = { pref = "x-apple.systempreferences:com.apple.preference.displays",           desc = "Displays" },
            p = { pref = "x-apple.systempreferences:com.apple.preference.security",                            desc = "Privacy & Security" },
            a = { pref = "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility", desc = "Accessibility" },
            w = { pref = "x-apple.systempreferences:com.apple.wifi-settings-extension",                             desc = "Wi-Fi" },
            e = { pref = "x-apple.systempreferences:com.apple.Network-Settings.extension",                       desc = "Network" },
            v = { pref = "x-apple.systempreferences:com.apple.NetworkExtensionSettingsUI.NESettingsUIExtension", desc = "VPN" },
            b = { pref = "x-apple.systempreferences:com.apple.preferences.Bluetooth",         desc = "Bluetooth" },
            k = { pref = "x-apple.systempreferences:com.apple.preference.keyboard",           desc = "Keyboard" },
            s = { pref = "x-apple.systempreferences:com.apple.preference.printfax",           desc = "Printers & Scanners" },
            l = { pref = "x-apple.systempreferences:com.apple.LoginItems-Settings.extension",                         desc = "Login Items & Extensions" },
            o = { pref = "x-apple.systempreferences:com.apple.Spotlight-Settings.extension",                         desc = "Spotlight" },
            r = { pref = "x-apple.systempreferences:com.apple.Wallpaper-Settings.extension",                         desc = "Wallpaper" },
            c = { pref = "x-apple.systempreferences:com.apple.Lock-Screen-Settings.extension",                       desc = "Lock Screen" },
            m = { pref = "x-apple.systempreferences:com.apple.Mouse-Settings.extension",                             desc = "Mouse" },
            t = { pref = "x-apple.systempreferences:com.apple.Screen-Time-Settings.extension",                       desc = "Screen Time" },
            f = { pref = "x-apple.systempreferences:com.apple.Focus-Settings.extension",                             desc = "Focus" },
            y = { pref = "x-apple.systempreferences:com.apple.Accessibility-Settings.extension?Display",        desc = "Accessibility: Display" },
            n = { pref = "x-apple.systempreferences:com.apple.Accessibility-Settings.extension?Motion",         desc = "Accessibility: Motion" },
            i = { pref = "x-apple.systempreferences:com.apple.Accessibility-Settings.extension?PointerControl", desc = "Accessibility: Pointer Control" },
            j = { pref = "x-apple.systempreferences:com.apple.Profiles-Settings.extension",                  desc = "Device Management" }
        }
    },

    system = {
        title = "System Actions:",
        handler = {
            field = "action",
            action = "functionCall"
        },
        customModule = "modules.hotkeys.modals.system"
    },

    macros = {
        title = "Macros:",
        handler = {
            field = "fn",
            action = "functionCall"
        },
        customModule = "modules.hotkeys.modals.macros"
    },

    routines = {
        title = "Routines:",
        handler = {
            field = "steps",
            action = "runSteps"
        },
        mappings = {}
    },

}

config.globalShortcuts = {
    { key = "a", modal = "apps",     desc = "Apps Modal" },
    { key = "f", modal = "finder",   desc = "Finder Modal" },
    { key = "w", modal = "websites", desc = "Websites Modal" },
    { key = "d", modal = "system",   desc = "System Modal" },
    { key = "s", modal = "settings", desc = "Settings Modal" },
    { key = "space", modal = "window", desc = "Window Management Modal" },
    { key = "m", modal = "macros",   desc = "Macros Modal" },
    { key = "r", modal = "routines", desc = "Routines Modal" },

    {
        key = "return",
        handler = {
            field = "app",
            action = "launchOrFocus"
        },
        mapping = { app = "Ghostty", desc = "Launch Ghostty" }
    },

    -- Transparent Ghostty: single separate instance so normal windows stay opaque.
    -- Keycode 42 is the key physically next to Return (# on German ISO),
    -- bound by code because hs.hotkey reads a key string starting with "#" as a raw keycode ("#42"),
    -- so "#" alone is an invalid key.
    {
        key = 42,
        handler = {
            field = "opacity",
            action = "launchGhosttyTransparent"
        },
        mapping = { opacity = "0.18", desc = "Transparent Ghostty (launch or focus)" }
    },

    -- Left-hand toggle while the right hand positions the mouse
    {
        key = "c",
        fn = function() require("modules.hotkeys.macros.auto-clicker").toggle() end,
        desc = "Toggle Auto-Clicker"
    },

    -- Mic mute toggle (Karabiner: F5 -> F18 -> Hammerspoon)
    {
        key = "f18",
        mods = {},
        fn = function() require("modules.mic_mute").toggle() end,
        desc = "Toggle Mic Mute"
    },

}

-- Configuration cache to avoid repeated reloading
local configCache = {
    isInitialized = false,
    localMappingsLoaded = {}
}

local function getLocalModulePath(modalName)
    return config.paths.localModulesBase .. modalName .. "_mappings"
end

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

    -- Loading local configurations

    -- Load local mappings for all defined modals
    for modalName, modal in pairs(config.modals) do
        -- Skip if we've already loaded this modal's mappings and not forcing reload
        if not forceReload and configCache.localMappingsLoaded[modalName] then goto continue end

        -- Only try to load local mappings if this isn't a custom implementation
        if not modal.customModule then
            local localPath = getLocalModulePath(modalName)

            -- Load the local mappings
            local localMappings = safeRequire(localPath, nil)

            -- If local mappings loaded successfully, replace the defaults
            if localMappings and next(localMappings) ~= nil then
                -- Using local mappings for " .. modalName
                modal.mappings = localMappings
            end
        end

        configCache.localMappingsLoaded[modalName] = true

        ::continue::
    end

    -- Load custom global shortcuts if available
    local localGlobalShortcuts = safeRequire(getLocalModulePath("global_shortcuts"), nil)

    if localGlobalShortcuts and next(localGlobalShortcuts) ~= nil then
        -- Using local global shortcuts configuration
        config.globalShortcuts = localGlobalShortcuts
    end

    configCache.isInitialized = true
    -- Configuration loading complete
end

-- Force reload of configuration files
function config.reloadConfigs(utils)
    -- Forcing configuration reload

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

    -- Configuration reload complete
end

return config
