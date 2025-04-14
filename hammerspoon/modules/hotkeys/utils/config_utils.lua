-- Configuration utilities for hotkeys module
local M = {}

-- Cache dependencies
local config = require("modules.hotkeys.config")
local log = require("modules.hotkeys.core.logging")

-- Helper function to create a shallow copy of a table
function M.shallowCopy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = v
    end
    return copy
end

-- Configuration loader with better error handling
function M.loadMappings(defaultMappings, localModulePath, modalName)
    if not modalName then
        return log.error("No modal name provided for loadMappings")
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
            log.debug("Replacing default mappings for " .. modalName)
        end
        
        -- Merge in local mappings in a single pass
        for k, v in pairs(localMappings) do
            if k ~= "_replaceDefaults" then
                combinedMappings[k] = v
                mergeCount = mergeCount + 1
            end
        end
        
        log.info(string.format("Loaded %d local mappings for %s", mergeCount, modalName))
    else
        if not status then
            log.debug("Could not load local mappings for " .. modalName .. ": " .. tostring(localMappings))
        end
    end
    
    return combinedMappings
end

return M 