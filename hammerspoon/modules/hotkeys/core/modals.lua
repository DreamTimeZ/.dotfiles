-- Modal management for hotkeys module
local M = {}

-- Cache dependencies
local config = require("modules.hotkeys.config")
local log = require("modules.hotkeys.core.logging")
local validation = require("modules.hotkeys.core.validation")
local actions = require("modules.hotkeys.core.actions")
local ui = require("modules.hotkeys.ui.ui")

-- Modal management with improved error handling and performance
function M.setupModal(mappings, title, modal)
    -- Validate essential parameters
    if not validation.validate({
        mappings = mappings, 
        modal = modal
    }, {isFatal = true}) then
        return nil
    end
    
    -- Additional validation for modal handler
    if not modal.handler or not modal.handler.field then
        return validation.handleError("Invalid modal definition: missing handler or field", true)
    end
    
    -- Create the modal
    local hotModal = hs.hotkey.modal.new()
    
    -- Pre-process bindings for better runtime performance
    local validBindings = {}
    local sortedHints = {}
    
    -- Validate and collect bindings in a single pass
    for key, binding in pairs(mappings) do
        local isValid, errorMsg = validation.validateBinding(binding, modal)
        
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
            log.warn("Skipping invalid binding for key '" .. key .. "': " .. (errorMsg or "unknown error"))
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
            ui.showFormattedAlert(hintTexts, title or "Actions:")
        end
    else
        -- Default behavior if no valid bindings
        function hotModal:entered()
            hs.alert.closeAll()
            ui.showFormattedAlert({"No actions available"}, title or "Actions:")
        end
    end
    
    -- Single action handler for all bindings
    local function handleModalAction(binding)
        local success = actions.executeAction(modal.handler, binding)
        
        if not success then
            validation.handleError("Failed to execute action", true)
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
        log.error("Invalid mappings provided to createModalModule")
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

return M 