-- Master module for all hotkey-related functionality.
-- Uses centralized configuration and utility functions for better maintainability

-- Load configuration and core modules
local config = require("modules.hotkeys.config")
local logging = require("modules.hotkeys.core.logging")
local actions = require("modules.hotkeys.core.actions")
local modals = require("modules.hotkeys.core.modals")
local configUtils = require("modules.hotkeys.utils.config_utils")

-- Store state
local globalHotkeys = {}
local modules = {}

-- Initialize hotkeys module

-- Load all config settings from local configurations
config.loadLocalConfigs(false, {
    info = logging.info,
    debug = logging.debug,
    warn = logging.warn,
    error = logging.error
})

-- Function to create a modal module
local function createModal(modalName)
    local modal = config.modals[modalName]
    
    if not modal then
        logging.error("Unknown modal: " .. modalName)
        return nil
    end
    
    -- Handle modules with custom implementations
    if modal.customModule then
        return require(modal.customModule)
    end
    
    -- Check for required fields
    if not modal.handler or not modal.handler.field or not modal.handler.action then
        logging.error("Invalid modal definition for " .. modalName .. ": missing handler information")
        return nil
    end
    
    -- Use mappings directly from the modal definition
    local mappings = modal.mappings or {}
    if not next(mappings) then
        logging.warn("No mappings found for modal: " .. modalName)
    end
    
    -- Create standard modal using the configuration
    return modals.createModalModule(
        mappings,
        modal.title or (modalName:gsub("^%l", string.upper) .. ":"),
        modal,
        modalName
    )
end

-- Exit all active modals and clear any alerts
local function exitAllModals()
    logging.debug("Exiting all modals")
    for _, mod in pairs(modules) do
        if mod.exit then mod.exit() end
    end
    hs.alert.closeAll()
end

-- Load all modal modules
local function loadModules()
    logging.info("Loading modal modules")
    local moduleCount = 0
    
    for modalName, _ in pairs(config.modals) do
        logging.debug("Loading modal: " .. modalName)
        modules[modalName] = createModal(modalName)
        moduleCount = moduleCount + 1
    end
    
    logging.info("Loaded " .. moduleCount .. " modals")
end

-- Create key bindings from configuration
local function createKeyBindings()
    -- Clear existing hotkeys
    for _, hotkey in ipairs(globalHotkeys) do
        hotkey:delete()
    end
    
    globalHotkeys = {}
    logging.info("Creating key bindings from configuration")
    
    local validCount = 0
    
    for _, shortcut in ipairs(config.globalShortcuts) do
        local mods = config.modifiers.hyper
        local key = shortcut.key
        
        if not key then
            logging.warn("Skipping shortcut without key")
            goto continue
        end
        
        local callback
        
        if shortcut.modal and modules[shortcut.modal] then
            -- Modal activator
            callback = function()
                logging.debug("Activating " .. shortcut.modal .. " modal")
                exitAllModals()
                modules[shortcut.modal].enter()
            end
        elseif shortcut.fn then
            -- Direct function call
            callback = function()
                logging.debug("Executing shortcut: " .. (shortcut.desc or shortcut.key))
                exitAllModals()
                shortcut.fn()
            end
        elseif shortcut.handler and shortcut.mapping then
            -- Action with handler and mapping
            callback = function()
                logging.debug("Executing action with handler")
                exitAllModals()
                actions.executeAction(shortcut.handler, shortcut.mapping)
            end
        else
            -- Skip invalid shortcuts
            logging.warn("Skipping invalid shortcut for key '" .. key .. "'")
            goto continue
        end
        
        -- Bind the hotkey and store it for later management
        local hotkey = hs.hotkey.bind(mods, key, callback)
        table.insert(globalHotkeys, hotkey)
        validCount = validCount + 1
        
        ::continue::
    end
    
    logging.info("Created " .. validCount .. " global hotkeys")
end



-- Initialize the module
local function initialize()
    loadModules()
    createKeyBindings()
    logging.info("Hotkeys module fully initialized")
end

-- Call initialize
initialize()

-- Return the module API
return {
    exitAllModals = exitAllModals,
    setLogLevel = logging.setLogLevel,
    setLoggingEnabled = logging.setLoggingEnabled,
    createModal = createModal,
    executeAction = actions.executeAction,
    reloadConfig = function()
        config.reloadConfigs({
            info = logging.info,
            debug = logging.debug,
            warn = logging.warn,
            error = logging.error
        })
        initialize()
    end
}
