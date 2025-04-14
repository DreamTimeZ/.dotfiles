-- Action handlers for hotkeys module
local M = {}

-- Cache dependencies
local config = require("modules.hotkeys.config.config")
local log = require("modules.hotkeys.core.logging")
local validation = require("modules.hotkeys.core.validation")

-- Core functionality with improved error handling
function M.launchOrFocus(appName)
    if not validation.validate(appName, {name = "app name"}) then return false end
    
    hs.application.launchOrFocus(appName)
    hs.timer.doAfter(config.delays.appActivation, function()
        local app = hs.application.get(appName)
        if app then app:activate() end
    end)
    return true
end

function M.openFinderFolder(path)
    if not validation.validate(path, {name = "path"}) then return false end
    
    if hs.fs.attributes(path) then
        hs.execute("open " .. path)
        return true
    else
        return validation.handleError("Path does not exist: " .. path, true)
    end
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

-- Map of action handlers for better performance and maintainability
local ACTION_HANDLERS = {
    launchOrFocus = M.launchOrFocus,
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
    end
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