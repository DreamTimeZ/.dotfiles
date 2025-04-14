-- Master module for all hotkey-related functionality.
-- Uses centralized configuration and utility functions for better maintainability

-- Load configuration and utility modules
local config = require("modules.hotkeys.config")
local utils = require("modules.hotkeys.utils")

-- Store state
local globalHotkeys = {}
local modules = {}

utils.info("Initializing hotkeys module")

-- Load all config settings from local configurations
config.loadLocalConfigs(false, utils)

-- Function to create a modal module
local function createModal(modalName)
    local modal = config.modals[modalName]
    
    if not modal then
        utils.error("Unknown modal: " .. modalName)
        return nil
    end
    
    -- Handle modules with custom implementations
    if modal.customModule then
        return require(modal.customModule)
    end
    
    -- Check for required fields
    if not modal.handler or not modal.handler.field or not modal.handler.action then
        utils.error("Invalid modal definition for " .. modalName .. ": missing handler information")
        return nil
    end
    
    -- Use mappings directly from the modal definition
    local mappings = modal.mappings or {}
    if not next(mappings) then
        utils.warn("No mappings found for modal: " .. modalName)
    end
    
    -- Create standard modal using the configuration
    return utils.createModalModule(
        mappings,
        modal.title or (modalName:gsub("^%l", string.upper) .. ":"),
        modal,
        modalName
    )
end

-- Exit all active modals and clear any alerts
local function exitAllModals()
    utils.debug("Exiting all modals")
    for _, mod in pairs(modules) do
        if mod.exit then mod.exit() end
    end
    hs.alert.closeAll()
end

-- Execute an action using a handler definition
local function executeAction(handler, mapping)
    if not handler or not handler.field or not handler.action or not mapping then
        utils.error("Invalid handler or mapping")
        return
    end
    
    utils.debug("Executing action: " .. handler.action)
    exitAllModals()
    
    local value = mapping[handler.field]
    if not value then
        utils.error("Missing required field in mapping: " .. handler.field)
        return
    end
    
    if handler.action == "launchOrFocus" then
        utils.launchOrFocus(value)
    elseif handler.action == "openURL" then
        utils.openURL(value)
    elseif handler.action == "openFinderFolder" then
        utils.openFinderFolder(value)
    elseif handler.action == "openSystemPreferencePane" then
        utils.openSystemPreferencePane(value)
    elseif type(value) == "function" then
        value()
    elseif utils[handler.action] and type(utils[handler.action]) == "function" then
        utils[handler.action](value)
    else
        utils.error("Unknown action handler: " .. handler.action)
    end
end

-- Load all modal modules
local function loadModules()
    utils.info("Loading modal modules")
    local moduleCount = 0
    
    for modalName, _ in pairs(config.modals) do
        utils.debug("Loading modal: " .. modalName)
        modules[modalName] = createModal(modalName)
        moduleCount = moduleCount + 1
    end
    
    utils.info("Loaded " .. moduleCount .. " modals")
end

-- Create key bindings from configuration
local function createKeyBindings()
    -- Clear existing hotkeys
    for _, hotkey in ipairs(globalHotkeys) do
        hotkey:delete()
    end
    
    globalHotkeys = {}
    utils.info("Creating key bindings from configuration")
    
    local validCount = 0
    
    for _, shortcut in ipairs(config.globalShortcuts) do
        local mods = config.modifiers.hyper
        local key = shortcut.key
        
        if not key then
            utils.warn("Skipping shortcut without key")
            goto continue
        end
        
        local callback
        
        if shortcut.modal and modules[shortcut.modal] then
            -- Modal activator
            callback = function()
                utils.debug("Activating " .. shortcut.modal .. " modal")
                exitAllModals()
                modules[shortcut.modal].enter()
            end
        elseif shortcut.fn then
            -- Direct function call
            callback = function()
                utils.debug("Executing shortcut: " .. (shortcut.desc or shortcut.key))
                exitAllModals()
                shortcut.fn()
            end
        elseif shortcut.handler and shortcut.mapping then
            -- Action with handler and mapping
            callback = function()
                utils.debug("Executing action with handler")
                executeAction(shortcut.handler, shortcut.mapping)
            end
        else
            -- Skip invalid shortcuts
            utils.warn("Skipping invalid shortcut for key '" .. key .. "'")
            goto continue
        end
        
        -- Bind the hotkey and store it for later management
        local hotkey = hs.hotkey.bind(mods, key, callback)
        table.insert(globalHotkeys, hotkey)
        validCount = validCount + 1
        
        ::continue::
    end
    
    utils.info("Created " .. validCount .. " global hotkeys")
end

-- Initialize the module
local function initialize()
    loadModules()
    createKeyBindings()
    utils.info("Hotkeys module fully initialized")
end

-- Call initialize
initialize()

-- Return the module API
return {
    exitAllModals = exitAllModals,
    setLogLevel = utils.setLogLevel,
    setLoggingEnabled = utils.setLoggingEnabled,
    createModal = createModal,
    executeAction = executeAction,
    reloadConfig = function()
        config.reloadConfigs(utils)
        initialize()
    end
}
