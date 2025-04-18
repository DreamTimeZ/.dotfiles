-- Window management modal implementation
local config = require("modules.hotkeys.config")
local modals = require("modules.hotkeys.core.modals")

-- Get the window-specific modal definition
local windowModal = config.modals.window

-- Window overlay data
local windowOverlays = {}
local showingOverlays = false

-- Cache frequently used Hammerspoon APIs
local hs_window = hs.window
local hs_mouse = hs.mouse
local hs_grid = hs.grid
local hs_canvas = hs.canvas
local hs_hotkey = hs.hotkey
local hs_timer = hs.timer
local hs_alert = hs.alert
local hs_geometry = hs.geometry

-- Constants for window operations
local RESIZE_DELTA = 25
local RESIZE_DELTA_2X = 50
local MIN_WINDOW_SIZE = 100

-- Constants for overlay handling
local OVERLAY_SIZE = 70
local OVERLAY_HALF_SIZE = 35
local OVERLAY_MAX_COUNT = 9
local OVERLAY_AUTO_HIDE_TIME = 5
local OVERLAY_TEXT_Y_POS = 45

-- Helper function to create window operations - optimized for performance
local function windowOperation(fn)
    return function()
        local win = hs_window.focusedWindow()
        if not win then return true end
        
        -- Execute the operation
        fn(win)
        return true
    end
end

-- Pre-calculated window position units using hs.geometry for better performance
local windowPositions = {
    -- Basic positions
    left = hs_geometry.rect(0, 0, 0.5, 1),
    right = hs_geometry.rect(0.5, 0, 0.5, 1),
    top = hs_geometry.rect(0, 0, 1, 0.5),
    bottom = hs_geometry.rect(0, 0.5, 1, 0.5),
    
    -- Corners
    topLeft = hs_geometry.rect(0, 0, 0.5, 0.5),
    topRight = hs_geometry.rect(0.5, 0, 0.5, 0.5),
    bottomLeft = hs_geometry.rect(0, 0.5, 0.5, 0.5),
    bottomRight = hs_geometry.rect(0.5, 0.5, 0.5, 0.5),
    
    -- Thirds
    leftThird = hs_geometry.rect(0, 0, 1/3, 1),
    middleThird = hs_geometry.rect(1/3, 0, 1/3, 1),
    rightThird = hs_geometry.rect(2/3, 0, 1/3, 1),
    
    -- Full screen
    fullScreen = hs_geometry.rect(0, 0, 1, 1)
}

-- Factory function for creating move functions - using pre-calculated geometry objects
local moveWindowFunctions = {}
for name, pos in pairs(windowPositions) do
    moveWindowFunctions[name] = windowOperation(function(win) win:moveToUnit(pos) end)
end

-- Special operations that require custom logic
local centerWindow = windowOperation(function(win) 
    local size = win:size()
    local screen = win:screen():frame()
    win:setTopLeft({
        x = (screen.w - size.w) / 2,
        y = (screen.h - size.h) / 2
    })
end)

local largerWindow = windowOperation(function(win)
    local f = win:frame()
    local screen = win:screen():frame()
    
    -- Pre-calculate all values at once
    local newX = math.max(f.x - RESIZE_DELTA, screen.x)
    local newY = math.max(f.y - RESIZE_DELTA, screen.y)
    local newW = math.min(f.w + RESIZE_DELTA_2X, screen.w - (newX - screen.x))
    local newH = math.min(f.h + RESIZE_DELTA_2X, screen.h - (newY - screen.y))
    
    win:setFrame({x = newX, y = newY, w = newW, h = newH})
end)

local smallerWindow = windowOperation(function(win)
    local f = win:frame()
    if f.w > MIN_WINDOW_SIZE and f.h > MIN_WINDOW_SIZE then
        win:setFrame({
            x = f.x + RESIZE_DELTA,
            y = f.y + RESIZE_DELTA,
            w = f.w - RESIZE_DELTA_2X,
            h = f.h - RESIZE_DELTA_2X
        })
    end
end)

local nextScreen = windowOperation(function(win)
    win:moveToScreen(win:screen():next())
end)

local prevScreen = windowOperation(function(win)
    win:moveToScreen(win:screen():previous())
end)

-- App window cycling - optimized with direct lookup
local function cycleAppWindows()
    local win = hs_window.focusedWindow()
    if not win then return true end
    
    local app = win:application()
    if not app then return true end
    
    local windows = app:allWindows()
    local numWindows = #windows
    if numWindows <= 1 then return true end
    
    local currentId = win:id()
    
    -- Find current window index and next window with direct lookup
    for i = 1, numWindows do
        if windows[i]:id() == currentId then
            local nextIdx = i < numWindows and i + 1 or 1
            local nextWin = windows[nextIdx]
            if nextWin:isMinimized() then nextWin:unminimize() end
            nextWin:focus()
            return true
        end
    end
    
    -- Fallback: focus first window if current not found
    local firstWin = windows[1]
    if firstWin:isMinimized() then firstWin:unminimize() end
    firstWin:focus()
    return true
end

-- Mouse warping - pre-calculate center coordinates once
local function mouseToWindow()
    local win = hs_window.focusedWindow()
    if not win then return true end
    
    local f = win:frame()
    hs_mouse.absolutePosition({x = f.x + f.w/2, y = f.y + f.h/2})
    return true
end

-- Grid selector - simplified
local function toggleGridSelector()
    local win = hs_window.focusedWindow()
    if win then hs_grid.show(win) end
    return true
end

-- Template for canvas elements to reuse in overlays
local canvasElementsTemplate = {
    {
        type = "rectangle",
        action = "fill",
        strokeColor = {white = 1, alpha = 0.9},
        strokeWidth = 2,
        roundedRectRadii = {xRadius = 10, yRadius = 10}
    },
    {
        type = "text",
        textSize = 48,
        textColor = {white = 1, alpha = 1},
        textAlignment = "center"
    },
    {
        type = "text",
        textSize = 10,
        textColor = {white = 1, alpha = 0.9},
        textAlignment = "center",
        frame = {x = 0, y = OVERLAY_TEXT_Y_POS, w = OVERLAY_SIZE, h = 20}
    }
}

-- Efficient overlay cleanup
local function hideWindowOverlays()
    for _, overlay in pairs(windowOverlays) do
        if overlay then
            if overlay.canvas then overlay.canvas:delete() end
            if overlay.hotkey then overlay.hotkey:delete() end
        end
    end
    
    if windowOverlays.escape then windowOverlays.escape:delete() end
    
    windowOverlays = {}
    showingOverlays = false
end

-- Deep clone function for canvas elements
local function cloneCanvasElements()
    local result = {}
    for i, element in ipairs(canvasElementsTemplate) do
        result[i] = {}
        for k, v in pairs(element) do
            if type(v) == "table" then
                result[i][k] = {}
                for k2, v2 in pairs(v) do
                    result[i][k][k2] = v2
                end
            else
                result[i][k] = v
            end
        end
    end
    return result
end

-- Optimized window overlay function
local function showWindowOverlays()
    if showingOverlays then
        hideWindowOverlays()
        return true
    end
    
    -- Collect visible windows
    local allWindows = {}
    local appCache = {}
    
    for _, win in ipairs(hs_window.allWindows()) do
        if win:isStandard() then
            table.insert(allWindows, win)
            
            -- Cache application names
            local app = win:application()
            local appId = app:pid()
            if not appCache[appId] then
                appCache[appId] = app:name() or "Unknown"
            end
        end
    end
    
    if #allWindows == 0 then return true end
    
    -- Optimized sort with cached app names
    table.sort(allWindows, function(a, b)
        local aVisible = a:isVisible()
        local bVisible = b:isVisible()
        
        if aVisible ~= bVisible then 
            return aVisible 
        end
        
        local aAppId = a:application():pid()
        local bAppId = b:application():pid()
        return (appCache[aAppId] or "") < (appCache[bAppId] or "")
    end)
    
    -- Create overlays (maximum of 9)
    local count = math.min(#allWindows, OVERLAY_MAX_COUNT)
    
    -- Single auto-hide timer for all overlays
    local autoHideTimer
    
    for i = 1, count do
        local win = allWindows[i]
        local frame = win:frame()
        if frame then
            -- Calculate position once
            local canvasX = frame.x + frame.w/2 - OVERLAY_HALF_SIZE
            local canvasY = frame.y + frame.h/2 - OVERLAY_HALF_SIZE
            
            local canvas = hs_canvas.new({
                x = canvasX, y = canvasY,
                w = OVERLAY_SIZE, h = OVERLAY_SIZE
            })
            
            -- Clone the template elements
            local elements = cloneCanvasElements()
            
            -- Update dynamic properties
            local isMinimized = win:isMinimized()
            elements[1].fillColor = isMinimized
                and {red = 0.3, green = 0.3, blue = 0.3, alpha = 0.8}
                or {red = 0, green = 0, blue = 0, alpha = 0.8}
            
            elements[2].text = tostring(i)
            
            local appId = win:application():pid()
            elements[3].text = appCache[appId] or "Unknown"
            
            -- Add all elements at once
            canvas:appendElements(elements)
            canvas:show()
            
            -- Create hotkey with direct window reference to avoid closure issues
            local windowRef = win
            windowOverlays[i] = {
                canvas = canvas,
                window = windowRef,
                hotkey = hs_hotkey.bind({}, tostring(i), function()
                    hideWindowOverlays()
                    
                    if windowRef:isMinimized() then
                        windowRef:unminimize()
                        hs_timer.doAfter(0.1, function() 
                            windowRef:focus() 
                        end)
                    else
                        windowRef:focus()
                    end
                end)
            }
        end
    end
    
    windowOverlays.escape = hs_hotkey.bind({}, "escape", hideWindowOverlays)
    showingOverlays = true
    
    -- Auto-hide overlays after delay
    if autoHideTimer then
        autoHideTimer:stop()
    end
    
    autoHideTimer = hs_timer.doAfter(OVERLAY_AUTO_HIDE_TIME, function()
        if showingOverlays then hideWindowOverlays() end
        autoHideTimer = nil
    end)
    
    return true
end

-- Define window management mappings with the most optimized functions
local windowMappings = {
    -- Main positions
    h = { action = moveWindowFunctions.left, desc = "Left Half" },
    j = { action = moveWindowFunctions.bottom, desc = "Bottom Half" },
    k = { action = moveWindowFunctions.top, desc = "Top Half" },
    l = { action = moveWindowFunctions.right, desc = "Right Half" },
    
    -- Corners
    u = { action = moveWindowFunctions.topLeft, desc = "Top Left Quarter" },
    i = { action = moveWindowFunctions.topRight, desc = "Top Right Quarter" },
    n = { action = moveWindowFunctions.bottomLeft, desc = "Bottom Left Quarter" },
    m = { action = moveWindowFunctions.bottomRight, desc = "Bottom Right Quarter" },
    
    -- Thirds
    ["1"] = { action = moveWindowFunctions.leftThird, desc = "Left Third" },
    ["2"] = { action = moveWindowFunctions.middleThird, desc = "Middle Third" },
    ["3"] = { action = moveWindowFunctions.rightThird, desc = "Right Third" },
    
    -- Full screen and center
    f = { action = moveWindowFunctions.fullScreen, desc = "Full Screen" },
    c = { action = centerWindow, desc = "Center Window" },
    
    -- Resize
    ["´"] = { action = largerWindow, desc = "Larger" },
    ["-"] = { action = smallerWindow, desc = "Smaller" },
    
    -- Move between screens
    ["right"] = { action = nextScreen, desc = "Next Screen" },
    ["left"] = { action = prevScreen, desc = "Previous Screen" },
    
    -- App window cycling
    a = { action = cycleAppWindows, desc = "Cycle App Windows" },
    
    -- Mouse warping
    w = { action = mouseToWindow, desc = "Mouse to Window" },
    
    -- Grid
    g = { action = toggleGridSelector, desc = "Grid Selector" },
    
    -- Number overlays
    ["0"] = { action = showWindowOverlays, desc = "Number Overlays" }
}

-- Store the mappings in the modal definition
windowModal.mappings = windowMappings

-- Create and return the modal module
return modals.createModalModule(
    windowMappings,
    windowModal.title,
    windowModal,
    "window"
) 