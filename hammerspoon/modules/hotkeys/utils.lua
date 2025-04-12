-- Utility functions for hotkeys module with focus on performance and maintainability
local M = {}

-- Debug settings
local debugEnabled = false

-- Core functionality
function M.launchOrFocus(appName)
    if not appName then return end
    hs.application.launchOrFocus(appName)
    -- Small delay to ensure app is ready before activation
    hs.timer.doAfter(0.1, function()
        local app = hs.application.get(appName)
        if app then app:activate() end
    end)
end

function M.openFinderFolder(path)
    if not path then return end
    if hs.fs.attributes(path) then
        hs.execute("open " .. path)
    else
        hs.alert.show("Path does not exist: " .. path)
    end
end

function M.openURL(url)
    if url then hs.urlevent.openURL(url) end
end

function M.openSystemPreferencePane(url)
    if not url then return end
    
    -- Check macOS version to determine which app to use
    local macOSVersion = hs.host.operatingSystemVersion()
    local isVentura = macOSVersion.major >= 13
    
    if isVentura then
        -- macOS Ventura or later uses System Settings
        hs.execute("killall 'System Settings' 2>/dev/null")
        hs.timer.doAfter(0.3, function() 
            hs.execute("open \"" .. url .. "\"") 
        end)
    else
        -- Earlier versions use System Preferences
        hs.execute("killall 'System Preferences' 2>/dev/null")
        hs.timer.doAfter(0.3, function() 
            hs.execute("open \"" .. url .. "\"") 
        end)
    end
end

function M.clearNotifications()
    hs.execute("killall NotificationCenter 2>/dev/null")
end

-- Debug helpers
function M.debug(message)
    if debugEnabled then print("[Hotkeys Debug] " .. message) end
end

function M.setDebug(enabled)
    debugEnabled = enabled
end

-- Modal management
function M.setupModal(mappings, title, actionType)
    local modal = hs.hotkey.modal.new()
    
    -- Modal entry behavior
    function modal:entered()
        hs.alert.closeAll()
        local hints = {}
        
        -- Collect hints with their descriptions
        for key, binding in pairs(mappings) do
            local description = binding.desc or key
            table.insert(hints, { 
                key = key, 
                text = string.format("[%s] %s", key, description),
                description = description
            })
        end
        
        -- Sort hints by description
        table.sort(hints, function(a, b) 
            return a.description:lower() < b.description:lower() 
        end)
        
        -- Extract the formatted text
        local sortedTexts = {}
        for _, hint in ipairs(hints) do
            table.insert(sortedTexts, hint.text)
        end
        
        M.showFormattedAlert(sortedTexts, title or "Actions:")
    end
    
    -- Bind all mapped keys
    for key, binding in pairs(mappings) do
        modal:bind("", key, function()
            if actionType == "app" and binding.app then
                M.launchOrFocus(binding.app)
            elseif actionType == "url" and binding.url then
                M.openURL(binding.url)
            elseif actionType == "path" and binding.path then
                M.openFinderFolder(binding.path)
            elseif actionType == "pref" and binding.pref then
                M.openSystemPreferencePane(binding.pref)
            elseif actionType == "fn" and binding.action then
                binding.action()
            end
            hs.alert.closeAll()
            modal:exit()
        end)
    end
    
    -- Always include escape to exit modal
    modal:bind("", "escape", function() hs.alert.closeAll() modal:exit() end)
    
    return modal
end

-- Configuration management
function M.loadMappings(defaultMappings, localModulePath, mappingType)
    -- Ensure defaultMappings is a table
    if not defaultMappings then defaultMappings = {} end
    
    -- Store original mappings in case we need to restore them
    local originalMappings = {}
    for k, v in pairs(defaultMappings) do
        originalMappings[k] = v
    end
    
    -- Try to load local mappings
    local status, localMappings = pcall(require, localModulePath)
    
    if status and type(localMappings) == "table" then
        if next(localMappings) ~= nil then
            -- Local mappings found - replace defaults completely
            M.debug("Using local mappings from " .. localModulePath)
            
            -- Validate local mappings (optional)
            local validatedMappings = {}
            for key, binding in pairs(localMappings) do
                local isValid = true
                
                -- Basic validation based on mapping type
                if mappingType == "app" and not binding.app then
                    M.debug("Invalid app mapping for key '" .. key .. "': missing 'app' field")
                    isValid = false
                elseif mappingType == "url" and not binding.url then
                    M.debug("Invalid website mapping for key '" .. key .. "': missing 'url' field")
                    isValid = false
                elseif mappingType == "path" and not binding.path then
                    M.debug("Invalid path mapping for key '" .. key .. "': missing 'path' field")
                    isValid = false
                elseif mappingType == "pref" and not binding.pref then
                    M.debug("Invalid preference mapping for key '" .. key .. "': missing 'pref' field")
                    isValid = false
                elseif mappingType == "fn" and not binding.action then
                    M.debug("Invalid function mapping for key '" .. key .. "': missing 'action' field")
                    isValid = false
                end
                
                if isValid then
                    validatedMappings[key] = binding
                end
            end
            
            return validatedMappings
        else
            M.debug("Local mappings file exists but is empty, keeping defaults")
        end
    elseif not status then
        -- Only log if it's not a "module not found" error
        if not string.match(localMappings, "module '" .. localModulePath .. "' not found") then
            M.debug("Error loading local mappings: " .. tostring(localMappings))
        else
            M.debug("No local mappings found at " .. localModulePath)
        end
    else
        M.debug("Error: Local mappings file does not return a table")
    end
    
    -- Return original mappings if we reach this point
    return originalMappings
end

-- UI helpers
function M.showFormattedAlert(content, title)
    local maxItemsPerLine = 5
    
    if type(content) ~= "table" then
        hs.alert.show(content)
        return
    end
    
    local formattedContent = title and (title .. "\n") or ""
    local currentLine = ""
    local itemCount = 0
    
    for _, item in ipairs(content) do
        if itemCount >= maxItemsPerLine then
            formattedContent = formattedContent .. currentLine .. "\n"
            currentLine = ""
            itemCount = 0
        end
        
        currentLine = currentLine .. item .. "  "
        itemCount = itemCount + 1
    end
    
    if currentLine ~= "" then
        formattedContent = formattedContent .. currentLine
    end
    
    hs.alert.show(formattedContent)
end

return M