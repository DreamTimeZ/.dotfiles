-- Utility functions for launching/focusing apps, opening folders, URLs, etc.
local M = {}

function M.launchOrFocus(appName)
    hs.application.launchOrFocus(appName)
    hs.timer.doAfter(0.1, function()
        local app = hs.application.get(appName)
        if app then app:activate() end
    end)
end

function M.openFinderFolder(path)
    if not path then
        hs.alert.show("Error: No path specified")
        return
    end
    -- Check if path exists before trying to open it
    local exists = hs.fs.attributes(path) ~= nil
    if not exists then
        hs.alert.show("Warning: Path does not exist: " .. path)
    end
    hs.execute("open " .. path)
end

function M.openURL(url)
    if not url then
        hs.alert.show("Error: No URL specified")
        return
    end
    hs.urlevent.openURL(url)
end

function M.openSystemPreferencePane(url)
    if not url then
        hs.alert.show("Error: No preference pane URL specified")
        return
    end
    -- Force-quit System Preferences so that it reopens fresh.
    hs.execute("killall 'System Preferences'")
    -- Wait 0.5 seconds for it to quit completely, then open the given URL.
    hs.timer.doAfter(0.5, function()
        hs.execute("open \"" .. url .. "\"")
    end)
end

function M.clearNotifications()
    hs.execute("killall NotificationCenter")
end

-- Debug function to log messages if debug mode is enabled
local debugEnabled = false
function M.debug(message)
    if debugEnabled then
        print("[Hotkeys Debug] " .. message)
    end
end

-- Enable or disable debug mode
function M.setDebug(enabled)
    debugEnabled = enabled
end

-- Validate the structure of a mapping entry based on its type
function M.validateMapping(key, mapping, mappingType)
    if type(mapping) ~= "table" then
        M.debug("Invalid mapping for key '" .. key .. "': not a table")
        return false
    end
    
    if mappingType == "app" and not mapping.app then
        M.debug("Invalid app mapping for key '" .. key .. "': missing 'app' field")
        return false
    elseif mappingType == "website" and not mapping.url then
        M.debug("Invalid website mapping for key '" .. key .. "': missing 'url' field")
        return false
    elseif mappingType == "finder" and not mapping.path then
        M.debug("Invalid finder mapping for key '" .. key .. "': missing 'path' field")
        return false
    end
    
    if not mapping.desc then
        M.debug("Warning: Mapping for key '" .. key .. "' is missing 'desc' field")
    end
    
    return true
end

-- Load local mappings and merge them with default mappings
function M.loadLocalMappings(defaultMappings, localModulePath, mappingType)
    if not defaultMappings then 
        defaultMappings = {} 
        M.debug("Creating empty default mappings table")
    end
    
    -- Store original mappings for error recovery
    local originalMappings = {}
    for k, v in pairs(defaultMappings) do
        originalMappings[k] = v
    end
    
    -- Try to load local mappings
    local status, localMappings = pcall(require, localModulePath)
    
    if status and type(localMappings) == "table" then
        M.debug("Successfully loaded local mappings from " .. localModulePath)
        
        if next(localMappings) ~= nil then
            -- If local mappings exist, use them instead of the defaults
            M.debug("Local mappings found - replacing default mappings")
            
            -- Clear default mappings
            defaultMappings = {}
            
            -- Add only the local mappings
            for key, binding in pairs(localMappings) do
                if M.validateMapping(key, binding, mappingType) then
                    defaultMappings[key] = binding
                    M.debug("Added mapping for key '" .. key .. "'")
                else
                    M.debug("Skipped invalid mapping for key '" .. key .. "'")
                end
            end
        else
            M.debug("Local mappings file exists but is empty, keeping defaults")
        end
    elseif not status then
        -- Only log if it's not a "module not found" error, which is expected
        if not string.match(localMappings, "module '" .. localModulePath .. "' not found") then
            M.debug("Error loading local mappings: " .. tostring(localMappings))
        else
            M.debug("No local mappings found at " .. localModulePath .. " (this is normal if you haven't created this file)")
        end
    else
        M.debug("Error: Local mappings file does not return a table")
    end
    
    -- Ensure we always return a valid table
    if type(defaultMappings) ~= "table" or next(defaultMappings) == nil then
        M.debug("Error: Corrupted or empty mappings, restoring defaults")
        return originalMappings
    end
    
    return defaultMappings
end

return M