-- Utility functions for hotkeys module with focus on performance and maintainability
local M = {}

-- Log a message at the specified level
function M.log(level, message)
    local config = require("modules.hotkeys.config")
    
    -- Check if logging is enabled and level is appropriate
    if not config.logging.enabled or level > config.logging.level then return end
    
    local levelName = config.logging.levelNames[level] or "UNKNOWN"
    local timestamp = os.date("%H:%M:%S")
    local prefix = string.format("[Hotkeys %s %s] ", levelName, timestamp)
    
    print(prefix .. message)
end

-- Convenience functions for each log level
function M.error(message) 
    local config = require("modules.hotkeys.config")
    M.log(config.logging.LEVELS.ERROR, message) 
end

function M.warn(message) 
    local config = require("modules.hotkeys.config")
    M.log(config.logging.LEVELS.WARN, message) 
end

function M.info(message) 
    local config = require("modules.hotkeys.config")
    M.log(config.logging.LEVELS.INFO, message) 
end

function M.debug(message) 
    local config = require("modules.hotkeys.config")
    M.log(config.logging.LEVELS.DEBUG, message) 
end

-- Set the logging level - updates the config
function M.setLogLevel(level)
    local config = require("modules.hotkeys.config")
    local LEVELS = config.logging.LEVELS
    
    if type(level) == "string" and LEVELS[level] then
        config.logging.level = LEVELS[level]
    elseif type(level) == "number" and level >= 0 and level <= 4 then
        config.logging.level = level
    else
        M.error("Invalid log level: " .. tostring(level))
    end
end

-- Enable or disable logging entirely
function M.setLoggingEnabled(enabled)
    local config = require("modules.hotkeys.config")
    config.logging.enabled = enabled
end

-- Error handling helper
local function handleError(message, isFatal)
    if isFatal then
        M.error(message)
        hs.alert.show("ERROR: " .. message)
        return false
    else
        M.warn(message)
        return nil
    end
end

-- Core functionality
function M.launchOrFocus(appName)
    if not appName then return handleError("No app name provided to launchOrFocus", false) end
    
    local config = require("modules.hotkeys.config")
    hs.application.launchOrFocus(appName)
    hs.timer.doAfter(config.delays.appActivation, function()
        local app = hs.application.get(appName)
        if app then app:activate() end
    end)
    return true
end

function M.openFinderFolder(path)
    if not path then return handleError("No path provided to openFinderFolder", false) end
    
    if hs.fs.attributes(path) then
        hs.execute("open " .. path)
        return true
    else
        return handleError("Path does not exist: " .. path, true)
    end
end

function M.openURL(url)
    if not url then return handleError("No URL provided to openURL", false) end
    
    hs.urlevent.openURL(url)
    return true
end

function M.openSystemPreferencePane(url)
    if not url then return handleError("No preference pane URL provided", false) end
    
    -- Get configuration
    local config = require("modules.hotkeys.config")
    local sysPrefs = config.systemPreferences
    local maxCheckAttempts = math.ceil(sysPrefs.maxWaitTime / sysPrefs.checkInterval)
    
    -- Determine which app to use based on macOS version
    local macOSVersion = hs.host.operatingSystemVersion()
    local appName = macOSVersion.major >= 13 and "System Settings" or "System Preferences"
    
    -- Check if the app is already running
    local systemApp = hs.application.get(appName)
    if systemApp then
        -- App is running - close it gracefully first
        systemApp:kill() -- Attempts to close the app gracefully
        
        -- Create a timer to check if the app has closed
        local counter = 0
        local terminationTimer = hs.timer.new(
            sysPrefs.checkInterval, 
            function()
                counter = counter + 1
                
                -- Check if app has closed
                if not hs.application.get(appName) then
                    -- App closed successfully, open the new preference pane
                    hs.execute("open \"" .. url .. "\"")
                    return false -- Stop the timer
                elseif counter >= maxCheckAttempts then
                    -- App didn't close in time, force kill it
                    hs.execute("killall '" .. appName .. "' 2>/dev/null")
                    
                    -- Wait a moment before opening the new URL
                    hs.timer.doAfter(sysPrefs.forceKillDelay, function() 
                        hs.execute("open \"" .. url .. "\"") 
                    end)
                    return false -- Stop the timer
                end
                
                return true -- Continue the timer
            end
        )
        
        -- Start the timer
        terminationTimer:start()
    else
        -- App is not running, just open the URL directly
        hs.execute("open \"" .. url .. "\"")
    end
    
    return true
end

function M.clearNotifications()
    hs.execute("killall NotificationCenter 2>/dev/null")
    return true
end

-- Modal management
function M.setupModal(mappings, title, actionType)
    local modal = hs.hotkey.modal.new()
    local config = require("modules.hotkeys.config")
    
    -- Modal entry behavior
    function modal:entered()
        hs.alert.closeAll()
        local hints = {}
        
        -- Collect hints with their descriptions
        for key, binding in pairs(mappings) do
            local description = binding.desc or key
            table.insert(hints, { 
                key = key, 
                text = string.format(config.ui.keyFormat, key, description),
                description = description
            })
        end
        
        -- Sort hints by description
        table.sort(hints, function(a, b) 
            return a.description:lower() < b.description:lower() 
        end)
        
        -- Extract the formatted text
        local sortedTexts = {}
        for _, hint in ipairs(hints) do
            table.insert(sortedTexts, hint.text)
        end
        
        M.showFormattedAlert(sortedTexts, title or "Actions:")
    end
    
    -- Action handler function to reduce code duplication
    local function handleAction(key, binding)
        if actionType == "app" and binding.app then
            M.launchOrFocus(binding.app)
        elseif actionType == "url" and binding.url then
            M.openURL(binding.url)
        elseif actionType == "path" and binding.path then
            M.openFinderFolder(binding.path)
        elseif actionType == "pref" and binding.pref then
            M.openSystemPreferencePane(binding.pref)
        elseif actionType == "fn" and binding.action then
            binding.action()
        else
            handleError("Invalid mapping for key '" .. key .. "' with actionType '" .. actionType .. "'", true)
        end
        
        hs.alert.closeAll()
        modal:exit()
    end
    
    -- Bind all mapped keys
    for key, binding in pairs(mappings) do
        modal:bind("", key, function() handleAction(key, binding) end)
    end
    
    -- Always include escape to exit modal
    modal:bind("", "escape", function() hs.alert.closeAll() modal:exit() end)
    
    return modal
end

-- Creates a standardized modal module to reduce redundancy
function M.createModalModule(mappings, title, actionType, localMappingsPath)
    -- Load local mappings if available
    if localMappingsPath then
        mappings = M.loadMappings(mappings, localMappingsPath, actionType)
    end
    
    -- Create the modal
    local modal = M.setupModal(mappings, title, actionType)
    
    -- Return the module API
    return {
        enter = function() modal:enter() end,
        exit = function() modal:exit() hs.alert.closeAll() end,
        isActive = function() return modal._eventport.m_enabled end,
        _modal = modal  -- Store reference to modal for potential later inspection
    }
end

-- Configuration management
function M.loadMappings(defaultMappings, localModulePath, mappingType)
    defaultMappings = defaultMappings or {}
    
    -- Try to load local mappings
    local status, localMappings = pcall(require, localModulePath)
    
    -- If no local mappings found, return defaults
    if not status or type(localMappings) ~= "table" or next(localMappings) == nil then
        M.debug("No local mappings found at " .. localModulePath .. ", using defaults")
        return defaultMappings
    end
    
    M.info("Loading local mappings from " .. localModulePath)
    
    -- Simple validation - only include mappings with required field
    local validatedMappings = {}
    local requiredField = mappingType -- app, url, path, pref, fn
    local validCount, invalidCount = 0, 0
    
    -- Special case for system actions which use "action" field
    if mappingType == "fn" then requiredField = "action" end
    
    for key, binding in pairs(localMappings) do
        if binding[requiredField] then
            validatedMappings[key] = binding
            validCount = validCount + 1
        else
            M.warn("Invalid mapping for key '" .. key .. "' in " .. localModulePath .. 
                   ": missing '" .. requiredField .. "' field")
            invalidCount = invalidCount + 1
        end
    end
    
    -- Log validation results
    if invalidCount > 0 then
        M.warn("Validation results for " .. localModulePath .. ": " .. 
              validCount .. " valid, " .. invalidCount .. " invalid mappings")
    end
    
    if validCount > 0 then
        M.info("Successfully loaded " .. validCount .. " mappings from " .. localModulePath)
        return validatedMappings
    else
        M.warn("No valid mappings found in " .. localModulePath .. ", using defaults")
        return defaultMappings
    end
end

-- UI helpers
function M.showFormattedAlert(content, title, options)
    local config = require("modules.hotkeys.config")
    
    -- Handle string content
    if type(content) ~= "table" then
        hs.alert.show(content, options and options.duration or nil)
        return
    end
    
    -- Initialize options with defaults
    options = options or {}
    local maxItemsPerLine = options.maxItemsPerLine or config.ui.maxItemsPerLine
    
    -- Format table content
    local formattedContent = title and (title .. "\n") or ""
    local currentLine = ""
    local itemCount = 0
    
    -- Process items
    for i, item in ipairs(content) do
        -- Start a new line if needed
        if itemCount >= maxItemsPerLine then
            formattedContent = formattedContent .. currentLine .. "\n"
            currentLine = ""
            itemCount = 0
        end
        
        currentLine = currentLine .. item .. "  "
        itemCount = itemCount + 1
        
        -- Handle last item
        if i == #content and currentLine ~= "" then
            formattedContent = formattedContent .. currentLine
        end
    end
    
    -- Show the alert
    hs.alert.show(formattedContent, options and options.duration or nil)
end

return M

