-- Validation helpers for hotkeys module
local M = {}

-- Cache dependencies
local config = require("modules.hotkeys.config.config")
local log = require("modules.hotkeys.core.logging")

local function handleError(message, isFatal)
    -- Log appropriate level based on severity
    if isFatal then
        log.error(message)
        -- Show minimal user-facing error for critical issues only
        hs.alert.show("Hotkeys Error", 2)
        return false
    else
        log.warn(message)
        return nil
    end
end

-- Unified validation function that can handle multiple parameter types
function M.validate(params, options)
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
function M.validateBinding(binding, modal)
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

-- Export error handler
M.handleError = handleError

return M 