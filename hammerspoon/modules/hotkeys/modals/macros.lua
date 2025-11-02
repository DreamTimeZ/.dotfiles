-- Optimized macros modal with dynamic macro support
local config = require("modules.hotkeys.config")
local logging = require("modules.hotkeys.core.logging")
local modals = require("modules.hotkeys.core.modals")

-- Get the macros-specific modal definition
local macrosModal = config.modals.macros

-- Macro registry for dynamic management
local macros = {
    ["Auto-Clicker"] = require("modules.hotkeys.macros.auto-clicker")
    -- Add new macros here: ["MacroName"] = require("path.to.macro")
}

-- Core functions
local function stopAll()
    logging.info("Stopping all macros")
    for name, macro in pairs(macros) do
        if macro.stop then macro.stop() end
    end
    return true
end

local function showStatus()
    logging.info("Showing macro status")
    local ui = require("modules.hotkeys.ui.ui")
    local config = require("modules.hotkeys.config.config")
    
    local statusLines = {}
    
    for name, macro in pairs(macros) do
        local status = "ERROR"
        if macro.isRunning then
            status = macro.isRunning() and "ON" or "OFF"
        end
        table.insert(statusLines, string.format(config.ui.keyFormat, name:sub(1,1):lower(), name .. " (" .. status .. ")"))
    end
    
    hs.timer.doAfter(0.1, function()
        hs.alert.closeAll()
        ui.showFormattedAlert(statusLines, "Macro Status:")
        hs.timer.doAfter(4, function()
            hs.alert.closeAll()
        end)
    end)
    
    return true
end

-- Dynamic action handler creation
local function createActionHandlers()
    local handlers = {
        stopAll = stopAll,
        showStatus = showStatus
    }
    
    -- Auto-generate toggle actions for each macro
    for name, macro in pairs(macros) do
        if macro.toggle then
            local actionName = "toggle" .. name:gsub("[^%w]", "")
            handlers[actionName] = function()
                logging.info("Toggling " .. name)
                macro.toggle()
                return true
            end
        end
    end
    
    return handlers
end

-- Load mappings with fallback to defaults
local function loadMappings()
    local mappingsPath = "modules.hotkeys.config.macros_mappings"
    local status, mappings = pcall(require, mappingsPath)
    local actionHandlers = createActionHandlers()

    if not status or not mappings then
        logging.warn("Using default macro mappings")
        return {
            a = { fn = actionHandlers.toggleAutoClicker, desc = "Toggle Auto-Clicker" },
            s = { fn = actionHandlers.stopAll, desc = "Stop All Macros" },
            i = { fn = actionHandlers.showStatus, desc = "Show Macro Status" }
        }
    end
    
    -- Convert mappings
    local convertedMappings = {}
    for key, mapping in pairs(mappings) do
        if mapping.action and actionHandlers[mapping.action] then
            convertedMappings[key] = {
                fn = actionHandlers[mapping.action],
                desc = mapping.desc or mapping.action
            }
        end
    end

    return convertedMappings
end

-- Initialize and create modal
local macroMappings = loadMappings()
macrosModal.mappings = macroMappings

return modals.createModalModule(
    macroMappings,
    macrosModal.title or "Macros:",
    macrosModal,
    "macros"
)