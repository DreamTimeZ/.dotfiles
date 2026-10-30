local M = {}

local config = require("modules.hotkeys.config")
local log = require("modules.hotkeys.core.logging")
local validation = require("modules.hotkeys.core.validation")
local actions = require("modules.hotkeys.core.actions")
local ui = require("modules.hotkeys.ui.ui")

function M.setupModal(mappings, title, modal)
    if not validation.validate({
        mappings = mappings,
        modal = modal
    }, {isFatal = true}) then
        return nil
    end

    if not modal.handler or not modal.handler.field then
        return validation.handleError("Invalid modal definition: missing handler or field", true)
    end

    local hotModal = hs.hotkey.modal.new()

    local validBindings = {}
    local sortedHints = {}

    for key, binding in pairs(mappings) do
        local isValid, errorMsg = validation.validateBinding(binding, modal)

        if isValid then
            validBindings[key] = binding

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

    if #sortedHints > 0 then
        table.sort(sortedHints, function(a, b)
            return a.description:lower() < b.description:lower()
        end)

        local hintTexts = {}
        for _, hint in ipairs(sortedHints) do
            table.insert(hintTexts, hint.text)
        end

        function hotModal:entered()
            hs.alert.closeAll()
            ui.showFormattedAlert(hintTexts, title or "Actions:")
        end
    else
        function hotModal:entered()
            hs.alert.closeAll()
            ui.showFormattedAlert({"No actions available"}, title or "Actions:")
        end
    end

    local function handleModalAction(binding)
        local success = actions.executeAction(modal.handler, binding)

        if not success then
            validation.handleError("Failed to execute action", false)
        end

        hs.alert.closeAll()
        hotModal:exit()
    end

    for key, binding in pairs(validBindings) do
        local boundBinding = binding
        hotModal:bind("", key, function() handleModalAction(boundBinding) end)
    end

    hotModal:bind("", "escape", function() hs.alert.closeAll() hotModal:exit() end)

    return hotModal
end

function M.createModalModule(mappings, title, modal, modalName)
    if not mappings or type(mappings) ~= "table" then
        log.error("Invalid mappings provided to createModalModule")
        mappings = {}
    end

    local hotModal = M.setupModal(mappings, title, modal)

    return {
        enter = function() hotModal:enter() end,
        exit = function() hotModal:exit() hs.alert.closeAll() end,
        isActive = function() return hotModal._eventport.m_enabled end
    }
end

return M
