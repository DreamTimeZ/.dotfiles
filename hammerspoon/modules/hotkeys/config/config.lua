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
    panelMaxScreenWidthFraction = 0.9,
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

    voice = {
        title = "Voice:",
        handler = {
            field = "fn",
            action = "functionCall"
        },
        mappings = {}
    },

}

-- A Hyper letter is only for a modal activator, H (it lists every shortcut, so it cannot sit in a
-- modal), or an action fired by a one-chord trigger (clicker, Voice Control), a time-critical one
-- (stop, interrupt, mute) or one used many times a day. Everything else goes in a topic modal.
-- Non-letter keys (Return, #) sit outside this letter budget. Once the free letters run out, such
-- actions take a free key of F13-F19 via Karabiner (the F18 pattern), never a modal.
config.globalShortcuts = {
    { key = "a", modal = "apps",     desc = "Apps Modal" },
    { key = "f", modal = "finder",   desc = "Finder Modal" },
    { key = "w", modal = "websites", desc = "Websites Modal" },
    { key = "d", modal = "system",   desc = "System Modal" },
    { key = "s", modal = "settings", desc = "Settings Modal" },
    { key = "space", modal = "window", desc = "Window Management Modal" },
    { key = "m", modal = "macros",   desc = "Macros Modal" },
    { key = "r", modal = "routines", desc = "Routines Modal" },
    { key = "v", modal = "voice",    desc = "Voice Modal" },

    { key = "h", fn = function() require("modules.hotkeys").showGlobalShortcuts() end, desc = "Show Global Shortcuts" },

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

-- Kept apart: a reload rebuilds the active mappings from these, so a removed or broken local file
-- restores the defaults and appended local entries never pile up.
local defaultGlobalShortcuts = config.globalShortcuts
local defaultModalMappings = {}
for modalName, modal in pairs(config.modals) do
    defaultModalMappings[modalName] = modal.mappings
end

local function getLocalModulePath(modalName)
    return config.paths.localModulesBase .. modalName .. "_mappings"
end

function config.safeRequire(modulePath, logFn)
    if not package.searchpath(modulePath, package.path) then return nil end
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

function config.loadLocalConfigs(logError)
    for modalName, modal in pairs(config.modals) do
        if not modal.customModule then
            local localPath = getLocalModulePath(modalName)

            local localMappings = config.safeRequire(localPath, logError)

            if localMappings and next(localMappings) ~= nil then
                modal.mappings = localMappings
            else
                modal.mappings = defaultModalMappings[modalName]
            end
        end
    end

    local localGlobalShortcuts = config.safeRequire(getLocalModulePath("global_shortcuts"), logError)

    local activeGlobalShortcuts = defaultGlobalShortcuts
    if localGlobalShortcuts and next(localGlobalShortcuts) ~= nil then
        activeGlobalShortcuts = localGlobalShortcuts
    end

    local extraGlobalShortcuts = config.safeRequire(getLocalModulePath("global_extra"), logError)
    config.globalShortcuts = {}
    for _, shortcut in ipairs(activeGlobalShortcuts) do
        table.insert(config.globalShortcuts, shortcut)
    end
    for _, shortcut in ipairs(extraGlobalShortcuts or {}) do
        table.insert(config.globalShortcuts, shortcut)
    end
end

function config.reloadConfigs(logError)
    for modalName, _ in pairs(config.modals) do
        package.loaded[getLocalModulePath(modalName)] = nil
    end

    package.loaded[getLocalModulePath("global_shortcuts")] = nil
    package.loaded[getLocalModulePath("global_extra")] = nil

    config.loadLocalConfigs(logError)
end

return config
