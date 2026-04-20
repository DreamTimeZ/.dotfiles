-- Optimized macros modal with dynamic macro support
local config = require("modules.hotkeys.config")
local logging = require("modules.hotkeys.core.logging")
local modals = require("modules.hotkeys.core.modals")

-- Get the macros-specific modal definition
local macrosModal = config.modals.macros

-- Macro registry for dynamic management
local macros = {
    ["Auto-Clicker"] = require("modules.hotkeys.macros.auto-clicker"),
    ["Recording"]   = require("modules.hotkeys.macros.rec"),
}

-- Optional local macros (loaded from dotfiles-private)
local localMacros = {}

for name, modulePath in pairs(localMacros) do
    local ok, mod = pcall(require, modulePath)
    if ok then macros[name] = mod end
end

-- Core functions
-- Fires stop on every macro unconditionally (each macro.stop is idempotent:
-- auto-clicker early-returns when not running, rec's script short-circuits
-- on "not recording"). Avoiding a pre-check loop eliminates both the O(N)
-- synchronous rec-status spawn and the "reported-stopped-before-async-
-- resolved" race. Per-macro outcome detail is still surfaced by each
-- macro's own alerts; the aggregate here confirms the batch fired.
local function stopAll()
    logging.info("Stopping all macros")
    for _, macro in pairs(macros) do
        if macro.stop then macro.stop() end
    end
    hs.alert.show("Stopped all macros")
    return true
end

local function showStatus()
    logging.info("Showing macro status")
    local ui = require("modules.hotkeys.ui.ui")

    -- Sort names for deterministic display (pairs order is undefined).
    local names = {}
    for name in pairs(macros) do table.insert(names, name) end
    table.sort(names)

    local statusLines = {}
    for _, name in ipairs(names) do
        local macro = macros[name]
        local status = "ERROR"
        if macro.isRunning then
            status = macro.isRunning() and "ON" or "OFF"
        end
        table.insert(statusLines, name .. ": " .. status)
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
            r = { fn = actionHandlers.toggleRecording, desc = "Toggle Recording" },
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
        else
            logging.warn("Unknown macro action '" .. tostring(mapping.action) .. "' for key '" .. tostring(key) .. "'")
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