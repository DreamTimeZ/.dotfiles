local M = {}

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
    local hints = {}

    for key, binding in pairs(mappings) do
        local isValid, errorMsg = validation.validateBinding(binding, modal)

        if isValid then
            validBindings[key] = binding
            table.insert(hints, { key = key, desc = binding.desc or key })
        else
            log.error("Skipping invalid binding for key '" .. key .. "': " .. (errorMsg or "unknown error"))
        end
    end

    table.sort(hints, function(a, b) return a.desc:lower() < b.desc:lower() end)
    if #hints == 0 then
        hints = { { desc = "No actions available" } }
    end

    function hotModal:entered()
        hs.alert.closeAll()
        ui.showShortcutPanel(title or "Actions:", hints)
    end

    -- Every exit path (action, Escape, exitAllModals) runs this.
    function hotModal:exited()
        ui.hideShortcutPanel()
    end

    -- exit() hides the panel before the action runs, so alerts the action shows stay visible.
    local function handleModalAction(binding)
        hotModal:exit()

        local success = actions.executeAction(modal.handler, binding)

        if not success then
            validation.handleError("Failed to execute action", false)
        end
    end

    for key, binding in pairs(validBindings) do
        local boundBinding = binding
        hotModal:bind("", key, function() handleModalAction(boundBinding) end)
    end

    hotModal:bind("", "escape", function() hotModal:exit() end)

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
        exit = function() hotModal:exit() end,
    }
end

return M
