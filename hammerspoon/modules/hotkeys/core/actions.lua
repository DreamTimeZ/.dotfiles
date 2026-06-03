-- Action handlers for hotkeys module
local M = {}

-- Cache dependencies
local config = require("modules.hotkeys.config.config")
local log = require("modules.hotkeys.core.logging")
local validation = require("modules.hotkeys.core.validation")

-- Core functionality with improved error handling
function M.launchOrFocus(appName)
    if not validation.validate(appName, {name = "app name"}) then return false end

    -- Check if appName is a full path (contains .app extension)
    if appName:match("%.app$") then
        -- Use shell command for full paths
        hs.execute(string.format('open -a "%s"', appName))

        -- Extract app name from bundle for focusing
        local extractedName = appName:match("([^/]+)%.app$")
        if extractedName then
            hs.timer.doAfter(config.delays.appActivation, function()
                local app = hs.application.get(extractedName)
                if app then app:activate() end
            end)
        end
    else
        -- Use standard launch method for app names
        hs.application.launchOrFocus(appName)
        hs.timer.doAfter(config.delays.appActivation, function()
            local app = hs.application.get(appName)
            if app then app:activate() end
        end)
    end
    return true
end

-- Launch or focus app using full path (for apps not in /Applications)
function M.launchOrFocusPath(appPath)
    if not validation.validate(appPath, {name = "app path"}) then return false end

    -- Use shell command to launch app with full path
    hs.execute(string.format('open -a "%s"', appPath))

    -- Extract app name from bundle for focusing
    local appName = appPath:match("([^/]+)%.app$")
    if appName then
        hs.timer.doAfter(config.delays.appActivation, function()
            local app = hs.application.get(appName)
            if app then app:activate() end
        end)
    end
    return true
end

-- Bundle id shared by every Ghostty process (normal and transparent alike).
local GHOSTTY_BUNDLE_ID = "com.mitchellh.ghostty"

-- hs.settings key persisting the transparent instance PID across Hammerspoon
-- reloads, so a reload does not orphan tracking and spawn a duplicate instance.
local TRANSPARENT_PID_KEY = "transparentGhosttyPid"

-- In-flight guard so a rapid double-press cannot spawn a second instance before
-- the first one has registered its PID.
local transparentGhosttyLaunching = false

-- Return the live transparent Ghostty app, or nil. Validates the bundle id so a
-- recycled PID belonging to an unrelated process is never mistaken for it.
local function liveTransparentGhostty()
    local pid = hs.settings.get(TRANSPARENT_PID_KEY)
    if not pid then return nil end
    local app = hs.application.applicationForPID(pid)
    if app and app:bundleID() == GHOSTTY_BUNDLE_ID then return app end
    hs.settings.clear(TRANSPARENT_PID_KEY)
    return nil
end

-- Focus the transparent Ghostty instance, launching it once if needed.
-- macOS Ghostty has no per-window opacity and toggle_background_opacity only
-- flips between the configured opacity and opaque, so the only SIP-safe way to
-- keep normal windows opaque while having transparent ones is a dedicated
-- instance whose background-opacity is overridden via --args. It reuses the
-- normal config (font, keybinds, ...) and quits once its last window closes.
function M.launchGhosttyTransparent(opacity)
    if not validation.validate(opacity, {name = "opacity"}) then return false end

    -- Rebuild the value from a number so it can never inject into the shell.
    local opacityNum = tonumber(opacity)
    if not opacityNum then
        return validation.handleError("Invalid opacity value: " .. tostring(opacity), true)
    end

    -- Reuse the existing transparent instance if it is still alive.
    local existing = liveTransparentGhostty()
    if existing then
        existing:activate()
        return true
    end

    -- A launch is already in flight; avoid spawning a second instance.
    if transparentGhosttyLaunching then return true end
    transparentGhosttyLaunching = true

    -- All Ghostty processes share one bundle id, so the freshly launched
    -- instance can only be identified by diffing the PID set before and after.
    local before = {}
    for _, app in ipairs(hs.application.applicationsForBundleID(GHOSTTY_BUNDLE_ID)) do
        before[app:pid()] = true
    end

    hs.execute(string.format(
        'open -na Ghostty.app --args --background-opacity=%.2f '
            .. '--background-opacity-cells=true --quit-after-last-window-closed=true',
        opacityNum
    ))

    local attempts = 0
    local found = false
    hs.timer.doUntil(
        function()
            return found or attempts >= config.delays.ghosttyLaunchMaxAttempts
        end,
        function()
            attempts = attempts + 1
            for _, app in ipairs(hs.application.applicationsForBundleID(GHOSTTY_BUNDLE_ID)) do
                if not before[app:pid()] then
                    hs.settings.set(TRANSPARENT_PID_KEY, app:pid())
                    app:activate()
                    found = true
                    break
                end
            end
            -- Release the guard once the instance is found or the search gives up.
            if found or attempts >= config.delays.ghosttyLaunchMaxAttempts then
                transparentGhosttyLaunching = false
            end
        end,
        config.delays.ghosttyLaunchPoll
    )

    return true
end

function M.openFinderFolder(path)
    if not validation.validate(path, {name = "path"}) then return false end

    -- Expand path if it contains a tilde
    if path:find("^~") then
        path = path:gsub("^~", os.getenv("HOME"))
    end

    if not hs.fs.attributes(path) then
        return validation.handleError("Path does not exist: " .. path, true)
    end

    -- Escape path for use in scripts and commands
    local escapedPath = path:gsub('"', '\\"')

    -- Check if Finder is running and frontmost
    local finder = hs.application.get("Finder")
    local finderActive = finder and finder:isFrontmost()

    if finderActive then
        -- Use a single AppleScript to check window count and take appropriate action
        local script = string.format([[
            tell application "Finder"
                if (count of windows) > 0 then
                    set target of front window to (POSIX file "%s")
                else
                    make new Finder window
                    set target of front window to (POSIX file "%s")
                end if
                activate
            end tell
        ]], escapedPath, escapedPath)

        hs.osascript.applescript(script)
    else
        -- Finder isn't frontmost or isn't running - use open command
        hs.execute(string.format('open "%s"', escapedPath))
    end

    return true
end

function M.openURL(url)
    if not validation.validate(url, {name = "URL"}) then return false end

    hs.urlevent.openURL(url)
    return true
end

function M.openSystemPreferencePane(url)
    if not validation.validate(url, {name = "preference pane URL"}) then return false end

    -- Cache frequently accessed configuration
    local sysPrefs = config.systemPreferences

    -- Determine which app to use based on macOS version
    local macOSVersion = hs.host.operatingSystemVersion()
    local appName = macOSVersion.major >= 13 and "System Settings" or "System Preferences"

    -- Try to open URL directly
    hs.execute("open \"" .. url .. "\"")

    -- Check if we successfully opened the URL
    local function checkSettingsOpened()
        local app = hs.application.get(appName)
        return app ~= nil and app:isFrontmost()
    end

    -- Set up a single timer for fallback approach
    hs.timer.doAfter(0.5, function()
        if not checkSettingsOpened() then
            log.debug("System settings didn't open correctly, trying fallback method")

            -- Close the app if it's running but not activated
            local app = hs.application.get(appName)
            if app then
                app:kill()

                -- Wait for app to close before reopening
                hs.timer.doAfter(sysPrefs.forceKillDelay, function()
                    hs.execute("open \"" .. url .. "\"")
                end)
            else
                -- Try launching again
                hs.execute("open \"" .. url .. "\"")
            end
        end
    end)

    return true
end

function M.runSteps(steps)
    if not validation.validate(steps, {name = "steps"}) then return false end
    if type(steps) ~= "table" then
        return validation.handleError("Steps must be a table", true)
    end

    local function executeStep(index)
        if index > #steps then return end
        local step = steps[index]
        local function fire()
            if step.url then
                hs.urlevent.openURL(step.url)
            elseif step.keys then
                -- Shape: {modifiers_table, character_string}, e.g. {{"cmd"}, "c"} or {{}, "f1"}
                hs.eventtap.keyStroke(step.keys[1], step.keys[2])
            elseif step.fn then
                step.fn()
            end
            executeStep(index + 1)
        end
        if step.delay and step.delay > 0 then
            hs.timer.doAfter(step.delay, fire)
        else
            fire()
        end
    end

    executeStep(1)
    return true
end

-- Map of action handlers for better performance and maintainability
local ACTION_HANDLERS = {
    launchOrFocus = M.launchOrFocus,
    launchOrFocusPath = M.launchOrFocusPath,
    launchGhosttyTransparent = M.launchGhosttyTransparent,
    openURL = M.openURL,
    openFinderFolder = M.openFinderFolder,
    openSystemPreferencePane = M.openSystemPreferencePane,
    clearNotifications = function()
        hs.execute("killall NotificationCenter 2>/dev/null")
        return true
    end,
    functionCall = function(fn)
        if type(fn) == "function" then
            return fn()
        end
        return validation.handleError("Invalid function provided to functionCall handler", true)
    end,
    runSteps = M.runSteps,
}

-- Export action handlers
M.handlers = ACTION_HANDLERS

-- Generic action executor with improved validation and error handling
function M.executeAction(handler, mapping)
    -- Validate essential parameters
    if not validation.validate({handler = handler, mapping = mapping}, {isFatal = true}) then
        return false
    end

    -- Validate handler structure
    if not handler.field or not handler.action then
        return validation.handleError("Invalid handler: missing field or action", true)
    end

    -- Get the value from mapping
    local value = mapping[handler.field]
    if not value then
        return validation.handleError("Missing required field in mapping: " .. handler.field, true)
    end

    -- Find the appropriate action handler
    local actionFn = ACTION_HANDLERS[handler.action]

    -- If not in ACTION_HANDLERS, check for module function
    if not actionFn then
        actionFn = M[handler.action]
        if type(actionFn) ~= "function" then
            -- Try fallbacks
            if mapping.action and type(mapping.action) == "function" then
                return mapping.action()
            elseif mapping.fn and type(mapping.fn) == "function" then
                return mapping.fn()
            else
                return validation.handleError("Unknown action handler: " .. handler.action, true)
            end
        end
    end

    -- Execute the action handler with the value
    return actionFn(value)
end

return M
