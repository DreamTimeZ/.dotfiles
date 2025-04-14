-- Master module for all hotkey-related functionality.
-- Uses centralized configuration and utility functions for better maintainability

-- Load configuration and utility modules
local config = require("modules.hotkeys.config")
local utils = require("modules.hotkeys.utils")

-- Store all created hotkeys for clean reloading
local globalHotkeys = {}

utils.info("Initializing hotkeys module")

-- Load all config settings from local configurations
config.loadLocalConfigs(false, utils)

-- Function to create a modal module based on type
local function createModalForType(moduleName)
    local modalDef = config.modalDefinitions[moduleName]
    
    if not modalDef then
        utils.error("Unknown modal type: " .. moduleName .. ". Add it to config.modalDefinitions to use it.")
        return nil
    end
    
    -- Handle modules with custom implementations
    if modalDef.hasCustomImpl and modalDef.customModule then
        return require(modalDef.customModule)
    end
    
    -- Create standard modal using the configuration
    local mappings = config[modalDef.mappingName]
    local localPath = config.paths.localModulesBase .. moduleName .. "_mappings"
    
    return utils.createModalModule(
        mappings,
        modalDef.title,
        modalDef.type,
        localPath
    )
end

-- Get modal modules from config.modalDefinitions and load them
local modules = {}
local moduleCount = 0

-- Load all modal modules efficiently
for moduleName, _ in pairs(config.modalDefinitions) do
    utils.debug("Loading modal module: " .. moduleName)
    modules[moduleName] = createModalForType(moduleName)
    moduleCount = moduleCount + 1
end

utils.info("Loaded " .. moduleCount .. " modal modules")

-- Function to exit all active modals and clear any alerts
local function exitAllModals()
    utils.debug("Exiting all modals")
    for _, mod in pairs(modules) do
        if mod.exit then mod.exit() end
    end
    hs.alert.closeAll()
end

-- Create key bindings from configuration
local function createKeyBindings()
    -- Clear existing hotkeys
    for _, hotkey in ipairs(globalHotkeys) do
        hotkey:delete()
    end
    
    globalHotkeys = {}
    utils.info("Creating key bindings from configuration")
    
    -- Set up global hotkeys from config
    local validCount = 0
    
    -- Set up global hotkeys from config
    for _, shortcut in ipairs(config.globalShortcuts) do
        -- Get keyboard modifiers
        local mods = config.modifiers.hyper
        local key = shortcut.key
        local callback
        
        if shortcut.action and modules[shortcut.action] then
            -- Modal activator
            callback = function()
                utils.debug("Activating " .. shortcut.action .. " modal")
                exitAllModals()
                modules[shortcut.action].enter()
            end
        elseif shortcut.fn then
            -- Direct function call
            callback = function()
                utils.debug("Executing shortcut: " .. (shortcut.desc or shortcut.key))
                exitAllModals()
                shortcut.fn()
            end
        else
            -- Skip invalid shortcuts
            utils.warn("Skipping invalid shortcut for key '" .. key .. "': missing action or function")
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

-- Initialize key bindings
createKeyBindings()

utils.info("Hotkeys module fully initialized")

-- Return the module API
return {
    exitAllModals = exitAllModals,
    setLogLevel = utils.setLogLevel,
    setLoggingEnabled = utils.setLoggingEnabled,
    createModalForType = createModalForType,  -- Expose factory function
    config = config
}
