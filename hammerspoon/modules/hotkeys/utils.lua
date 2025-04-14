-- Utility functions for hotkeys module with focus on performance and maintainability
local M = {}

-- Cache config reference to avoid redundant requires
local config = require("modules.hotkeys.config")

-- Log a message at the specified level
function M.log(level, message)
    -- Check if logging is enabled and level is appropriate
    if not config.logging.enabled or level > config.logging.level then return end
    
    local levelName = config.logging.levelNames[level] or "UNKNOWN"
    local timestamp = os.date("%H:%M:%S")
    local prefix = string.format("[Hotkeys %s %s] ", levelName, timestamp)
    
    print(prefix .. message)
end

-- Convenience functions for each log level
function M.error(message) 
    M.log(config.logging.LEVELS.ERROR, message) 
end

function M.warn(message) 
    M.log(config.logging.LEVELS.WARN, message) 
end

function M.info(message) 
    M.log(config.logging.LEVELS.INFO, message) 
end

function M.debug(message) 
    M.log(config.logging.LEVELS.DEBUG, message) 
end

-- Set the logging level
function M.setLogLevel(level)
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
    config.logging.enabled = enabled
end

-- Error handling helper with improved consistency
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

-- Validate if a binding has required fields for the modal
local function validateBinding(key, binding, modal)
    if not binding then
        return false, "Binding is nil"
    end
    
    if not modal or not modal.handler or not modal.handler.field then
        return false, "Invalid modal or handler definition"
    end
    
    -- Check if the binding has the required field
    local requiredField = modal.handler.field
    if not binding[requiredField] then
        return false, "Missing " .. requiredField .. " field"
    end
    
    return true, nil
end

-- Core functionality with improved error handling
function M.launchOrFocus(appName)
    if not appName then return handleError("No app name provided to launchOrFocus", false) end
    
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
    local sysPrefs = config.systemPreferences
    
    -- Determine which app to use based on macOS version
    local macOSVersion = hs.host.operatingSystemVersion()
    local appName = macOSVersion.major >= 13 and "System Settings" or "System Preferences"
    
    -- Always try to open the URL directly first - this will work in most cases
    -- and will switch to the correct pane if settings is already open
    hs.execute("open \"" .. url .. "\"")
    
    -- Check if we successfully opened the URL
    local function checkSettingsOpened()
        local app = hs.application.get(appName)
        return app ~= nil and app:isFrontmost()
    end
    
    -- If the app didn't launch or activate properly, try a fallback approach
    hs.timer.doAfter(0.5, function()
        if not checkSettingsOpened() then
            M.debug("System settings didn't open correctly, trying fallback method")
            
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

function M.clearNotifications()
    hs.execute("killall NotificationCenter 2>/dev/null")
    return true
end

-- Modal management with improved error handling
function M.setupModal(mappings, title, modal)
    if not mappings or type(mappings) ~= "table" then
        return handleError("Invalid mappings table for modal setup", true)
    end
    
    if not modal or not modal.handler then
        return handleError("Invalid modal definition for modal setup", true)
    end
    
    local hotModal = hs.hotkey.modal.new()
    
    -- Modal entry behavior
    function hotModal:entered()
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
        -- Validate the binding first
        local valid, error = validateBinding(key, binding, modal)
        if not valid then
            handleError("Invalid mapping for key '" .. key .. "': " .. error, true)
            return
        end
        
        local success = false
        local handler = modal.handler
        local fieldName = handler.field
        local fieldValue = binding[fieldName]
        
        -- Execute the action based on the handler type
        if handler.action == "launchOrFocus" then
            success = M.launchOrFocus(fieldValue)
        elseif handler.action == "openURL" then
            success = M.openURL(fieldValue)
        elseif handler.action == "openFinderFolder" then
            success = M.openFinderFolder(fieldValue)
        elseif handler.action == "openSystemPreferencePane" then
            success = M.openSystemPreferencePane(fieldValue)
        elseif handler.action == "functionCall" and type(fieldValue) == "function" then
            -- For function calls, execute the function directly
            success = fieldValue()
        elseif M[handler.action] and type(M[handler.action]) == "function" then
            -- Try to call a function in the utils module directly
            success = M[handler.action](fieldValue)
        -- Fallback for custom handlers
        elseif binding.action and type(binding.action) == "function" then
            success = binding.action()
        elseif binding.fn and type(binding.fn) == "function" then
            success = binding.fn()
        else
            handleError("Unsupported action: " .. key .. " with handler " .. handler.action, true)
            return
        end
        
        if not success then
            -- Only show error if action function didn't already show one
            handleError("Failed to execute action for key '" .. key .. "'", true)
        end
        
        hs.alert.closeAll()
        hotModal:exit()
    end
    
    -- Bind all mapped keys
    for key, binding in pairs(mappings) do
        hotModal:bind("", key, function() handleAction(key, binding) end)
    end
    
    -- Always include escape to exit modal
    hotModal:bind("", "escape", function() hs.alert.closeAll() hotModal:exit() end)
    
    return hotModal
end

-- Creates a standardized modal module
function M.createModalModule(mappings, title, modal, modalName)
    if not mappings or type(mappings) ~= "table" then
        M.error("Invalid mappings provided to createModalModule")
        mappings = {}
    end
    
    -- Create the modal
    local hotModal = M.setupModal(mappings, title, modal)
    
    -- Return the module API
    return {
        enter = function() hotModal:enter() end,
        exit = function() hotModal:exit() hs.alert.closeAll() end,
        isActive = function() return hotModal._eventport.m_enabled end
    }
end

-- UI helpers
function M.showFormattedAlert(content, title, options)
    -- Handle string content
    if type(content) ~= "table" then
        content = {tostring(content)}
    end
    
    -- Set default options
    options = options or {}
    
    -- Calculate max items per line
    local maxItemsPerLine = options.maxItemsPerLine or config.ui.maxItemsPerLine
    local totalItems = #content
    
    -- Format in rows
    local formattedText = title and (title .. "\n") or ""
    local lineItems = {}
    
    for i, item in ipairs(content) do
        table.insert(lineItems, item)
        
        -- Check if we need a new line
        if #lineItems >= maxItemsPerLine or i == totalItems then
            formattedText = formattedText .. table.concat(lineItems, "   ")
            if i < totalItems then
                formattedText = formattedText .. "\n"
            end
            lineItems = {}
        end
    end
    
    -- Show the alert with all options
    hs.alert.show(formattedText, options)
end

-- Simple configuration loader
function M.loadMappings(defaultMappings, localModulePath, modalName)
    -- Start with default mappings
    local combinedMappings = {}
    
    -- Copy default mappings
    if defaultMappings and type(defaultMappings) == "table" then
        for k, v in pairs(defaultMappings) do
            combinedMappings[k] = v
        end
    end
    
    -- Try to load local customizations
    local status, localMappings = pcall(require, config.paths.localModulesBase .. modalName .. "_mappings")
    
    -- If local mappings loaded successfully, merge or replace
    if status and type(localMappings) == "table" then
        -- Check if local mappings completely replace defaults
        if localMappings._replaceDefaults then
            combinedMappings = {}
        end
        
        -- Merge in local mappings
        for k, v in pairs(localMappings) do
            if k ~= "_replaceDefaults" then
                combinedMappings[k] = v
            end
        end
        
        M.info("Local mappings loaded and merged for " .. modalName)
    end
    
    return combinedMappings
end

return M

