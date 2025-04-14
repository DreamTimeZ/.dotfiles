-- Utility functions for hotkeys module with focus on performance and maintainability
local M = {}

-- Cache config reference to avoid redundant requires
local config = require("modules.hotkeys.config")

-- Log a message at the specified level with minimal overhead
function M.log(level, message)
    -- Check if logging is enabled and level is appropriate
    if not config.logging.enabled or level > config.logging.level then return end
    
    local levelName = config.logging.levelNames[level] or "UNKNOWN"
    local timestamp = os.date("%H:%M:%S")
    
    -- Use string format instead of concatenation for better performance
    print(string.format("[Hotkeys %s %s] %s", levelName, timestamp, message))
end

-- Create optimized logging functions using a factory pattern to reduce code duplication
local function createLogFunction(level)
    local levelValue = config.logging.LEVELS[level]
    return function(message)
        if config.logging.enabled and levelValue <= config.logging.level then
            M.log(levelValue, message)
        end
    end
end

-- Generate all logging functions at once
M.error = createLogFunction("ERROR")
M.warn = createLogFunction("WARN")
M.info = createLogFunction("INFO")
M.debug = createLogFunction("DEBUG")

-- Set the logging level
function M.setLogLevel(level)
    if type(level) == "string" and config.logging.LEVELS[level] then
        config.logging.level = config.logging.LEVELS[level]
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

local function handleError(message, isFatal)
    -- Log appropriate level based on severity
    if isFatal then
        M.error(message)
        -- Only show alert for fatal errors to avoid UI clutter
        hs.alert.show("ERROR: " .. message)
        return false
    else
        M.warn(message)
        return nil
    end
end

-- Unified validation function that can handle multiple parameter types
local function validate(params, options)
    options = options or {}
    local isFatal = options.isFatal or false
    
    -- Handle single parameter validation
    if type(params) ~= "table" or options.singleParam then
        local name = options.name or "parameter"
        if not params then
            return handleError("No " .. name .. " provided", isFatal)
        end
        return true
    end
    
    -- Handle multiple parameters validation
    for name, value in pairs(params) do
        if not value then
            return handleError("Missing required " .. name, isFatal)
        end
    end
    
    return true
end

-- Specialized binding validation for modals
local function validateBinding(binding, modal)
    -- Check binding and modal objects
    if not binding or not modal then
        return false, "Invalid binding or modal configuration"
    end
    
    -- Validate modal structure
    if not modal.handler or not modal.handler.field then
        return false, "Invalid modal handler configuration"
    end
    
    -- Check required field in binding
    local requiredField = modal.handler.field
    if not binding[requiredField] then
        return false, "Missing " .. requiredField .. " field in binding"
    end
    
    return true, nil
end

-- Core functionality with improved error handling
function M.launchOrFocus(appName)
    if not validate(appName, {name = "app name"}) then return false end
    
    hs.application.launchOrFocus(appName)
    hs.timer.doAfter(config.delays.appActivation, function()
        local app = hs.application.get(appName)
        if app then app:activate() end
    end)
    return true
end

function M.openFinderFolder(path)
    if not validate(path, {name = "path"}) then return false end
    
    if hs.fs.attributes(path) then
        hs.execute("open " .. path)
        return true
    else
        return handleError("Path does not exist: " .. path, true)
    end
end

function M.openURL(url)
    if not validate(url, {name = "URL"}) then return false end
    
    hs.urlevent.openURL(url)
    return true
end

function M.openSystemPreferencePane(url)
    if not validate(url, {name = "preference pane URL"}) then return false end
    
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
        return handleError("Invalid function provided to functionCall handler", true)
    end
}

-- Export action handlers for use in other modules
M.actions = ACTION_HANDLERS

-- Generic action executor with improved validation and error handling
function M.executeAction(handler, mapping)
    -- Validate essential parameters
    if not validate({handler = handler, mapping = mapping}, {isFatal = true}) then
        return false
    end
    
    -- Validate handler structure
    if not handler.field or not handler.action then
        return handleError("Invalid handler: missing field or action", true)
    end
    
    -- Get the value from mapping
    local value = mapping[handler.field]
    if not value then
        return handleError("Missing required field in mapping: " .. handler.field, true)
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
                return handleError("Unknown action handler: " .. handler.action, true)
            end
        end
    end
    
    -- Execute the action handler with the value
    return actionFn(value)
end

-- Modal management with improved error handling and performance
function M.setupModal(mappings, title, modal)
    -- Validate essential parameters
    if not validate({
        mappings = mappings, 
        modal = modal
    }, {isFatal = true}) then
        return nil
    end
    
    -- Additional validation for modal handler
    if not modal.handler or not modal.handler.field then
        return handleError("Invalid modal definition: missing handler or field", true)
    end
    
    -- Create the modal
    local hotModal = hs.hotkey.modal.new()
    
    -- Pre-process bindings for better runtime performance
    local validBindings = {}
    local sortedHints = {}
    
    -- Validate and collect bindings in a single pass
    for key, binding in pairs(mappings) do
        local isValid, errorMsg = validateBinding(binding, modal)
        
        if isValid then
            -- Store valid binding
            validBindings[key] = binding
            
            -- Create hint entry (using description or fallback to key)
            local description = binding.desc or key
            table.insert(sortedHints, {
                key = key,
                text = string.format(config.ui.keyFormat, key, description),
                description = description
            })
        else
            M.warn("Skipping invalid binding for key '" .. key .. "': " .. (errorMsg or "unknown error"))
        end
    end
    
    -- Sort hints by description once (only if we have hints)
    if #sortedHints > 0 then
        table.sort(sortedHints, function(a, b)
            return a.description:lower() < b.description:lower()
        end)
        
        -- Extract sorted texts (only once)
        local hintTexts = {}
        for _, hint in ipairs(sortedHints) do
            table.insert(hintTexts, hint.text)
        end
        
        -- Set modal entry behavior
        function hotModal:entered()
            hs.alert.closeAll()
            M.showFormattedAlert(hintTexts, title or "Actions:")
        end
    else
        -- Default behavior if no valid bindings
        function hotModal:entered()
            hs.alert.closeAll()
            M.showFormattedAlert({"No actions available"}, title or "Actions:")
        end
    end
    
    -- Single action handler for all bindings
    local function handleModalAction(binding)
        local success = M.executeAction(modal.handler, binding)
        
        if not success then
            handleError("Failed to execute action", true)
        end
        
        hs.alert.closeAll()
        hotModal:exit()
    end
    
    -- Bind all valid keys in a single pass
    for key, binding in pairs(validBindings) do
        -- Use local binding capture
        local boundBinding = binding
        hotModal:bind("", key, function() handleModalAction(boundBinding) end)
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
    options = options or {}
    
    -- Initialize result array with pre-allocated capacity to avoid resizing
    local formattedLines = title and {title} or {}
    
    -- Cache config value for performance
    local maxItemsPerLine = options.maxItemsPerLine or config.ui.maxItemsPerLine
    
    -- If content is already a formatted array, use it directly but respect maxItemsPerLine
    if type(content) == "table" and #content > 0 and type(content[1]) == "string" then
        -- Process formatted key hints in batches according to maxItemsPerLine
        local lineItems = {}
        local totalItems = #content
        
        for i, item in ipairs(content) do
            table.insert(lineItems, item)
            
            -- Flush line when full or at the end
            if #lineItems >= maxItemsPerLine or i == totalItems then
                table.insert(formattedLines, table.concat(lineItems, "   "))
                lineItems = {}
            end
        end
    else
        -- Handle string or table content
        local items = type(content) == "table" and content or {tostring(content)}
        
        -- Format items into lines with maximum items per line
        if #items > 0 then
            local lineItems = {}
            local totalItems = #items
            
            for i, item in ipairs(items) do
                table.insert(lineItems, item)
                
                -- Flush line when full or at the end
                if #lineItems >= maxItemsPerLine or i == totalItems then
                    table.insert(formattedLines, table.concat(lineItems, "   "))
                    lineItems = {}
                end
            end
        end
    end
    
    -- Show the alert with all combined lines
    hs.alert.show(table.concat(formattedLines, "\n"), options)
end

-- Helper function to create a shallow copy of a table
function M.shallowCopy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = v
    end
    return copy
end

-- Optimized configuration loader with better error handling
function M.loadMappings(defaultMappings, localModulePath, modalName)
    if not modalName then
        return handleError("No modal name provided for loadMappings", true)
    end
    
    -- Start with default mappings or empty table
    local combinedMappings = defaultMappings and M.shallowCopy(defaultMappings) or {}
    
    -- Determine the local path to use
    local localPath = localModulePath or (config.paths.localModulesBase .. modalName .. "_mappings")
    
    -- Try to load local customizations using pcall for safety
    local status, localMappings = pcall(require, localPath)
    
    -- Only process if load was successful and returned a table
    if status and type(localMappings) == "table" then
        local replaceMode = localMappings._replaceDefaults
        local mergeCount = 0
        
        -- If replacement mode, start with empty table
        if replaceMode then
            combinedMappings = {}
            M.debug("Replacing default mappings for " .. modalName)
        end
        
        -- Merge in local mappings in a single pass
        for k, v in pairs(localMappings) do
            if k ~= "_replaceDefaults" then
                combinedMappings[k] = v
                mergeCount = mergeCount + 1
            end
        end
        
        M.info(string.format("Loaded %d local mappings for %s", mergeCount, modalName))
    else
        if not status then
            M.debug("Could not load local mappings for " .. modalName .. ": " .. tostring(localMappings))
        end
    end
    
    return combinedMappings
end

return M

