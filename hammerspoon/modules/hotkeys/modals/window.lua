-- Window management modal implementation
local config = require("modules.hotkeys.config")
local logging = require("modules.hotkeys.core.logging")
local actions = require("modules.hotkeys.core.actions")
local modals = require("modules.hotkeys.core.modals")
local ui = require("modules.hotkeys.ui.ui")

-- Get the window-specific modal definition
local windowModal = config.modals.window

-- Window history for undo/redo functionality
local windowHistory = {}
local historyIndex = 0
local MAX_HISTORY = 20

-- Window overlay data
local windowOverlays = {}
local showingOverlays = false

-- Helper function to create window operations
local function windowOperation(fn, noHistory)
    return function()
        local win = hs.window.focusedWindow()
        if not win then
            hs.alert.show("No focused window")
            return true
        end
        
        -- Save window state for undo functionality if this is a position-changing operation
        if not noHistory then
            -- Only save if we have a position to save
            if win:frame() then
                -- Remove any redo history
                while #windowHistory > historyIndex do
                    table.remove(windowHistory)
                end
                
                -- Add current position to history
                if historyIndex < MAX_HISTORY then
                    table.insert(windowHistory, {
                        id = win:id(),
                        frame = win:frame(),
                        screen = win:screen():id()
                    })
                    historyIndex = historyIndex + 1
                else
                    -- Remove oldest entry
                    table.remove(windowHistory, 1)
                    table.insert(windowHistory, {
                        id = win:id(),
                        frame = win:frame(),
                        screen = win:screen():id()
                    })
                end
            end
        end
        
        -- Execute the operation
        fn(win)
        return true
    end
end

-- Define basic window operations
local function moveWindowLeft()
    return windowOperation(function(win) win:moveToUnit({0, 0, 0.5, 1}) end, false)()
end

local function moveWindowRight()
    return windowOperation(function(win) win:moveToUnit({0.5, 0, 0.5, 1}) end, false)()
end

local function moveWindowTop()
    return windowOperation(function(win) win:moveToUnit({0, 0, 1, 0.5}) end, false)()
end

local function moveWindowBottom()
    return windowOperation(function(win) win:moveToUnit({0, 0.5, 1, 0.5}) end, false)()
end

local function moveWindowTopLeft()
    return windowOperation(function(win) win:moveToUnit({0, 0, 0.5, 0.5}) end, false)()
end

local function moveWindowTopRight()
    return windowOperation(function(win) win:moveToUnit({0.5, 0, 0.5, 0.5}) end, false)()
end

local function moveWindowBottomLeft()
    return windowOperation(function(win) win:moveToUnit({0, 0.5, 0.5, 0.5}) end, false)()
end

local function moveWindowBottomRight()
    return windowOperation(function(win) win:moveToUnit({0.5, 0.5, 0.5, 0.5}) end, false)()
end

local function moveWindowLeftThird()
    return windowOperation(function(win) win:moveToUnit({0, 0, 1/3, 1}) end, false)()
end

local function moveWindowMiddleThird()
    return windowOperation(function(win) win:moveToUnit({1/3, 0, 1/3, 1}) end, false)()
end

local function moveWindowRightThird()
    return windowOperation(function(win) win:moveToUnit({2/3, 0, 1/3, 1}) end, false)()
end

local function fullScreenWindow()
    return windowOperation(function(win) win:moveToUnit({0, 0, 1, 1}) end, false)()
end

local function centerWindow()
    return windowOperation(function(win) 
        local size = win:size()
        local screen = win:screen():frame()
        local x = (screen.w - size.w) / 2
        local y = (screen.h - size.h) / 2
        win:setTopLeft({x = x, y = y})
    end, false)()
end

local function largerWindow()
    return windowOperation(function(win)
        local f = win:frame()
        local screen = win:screen():frame()
        win:setFrame({
            x = math.max(f.x - 25, screen.x),
            y = math.max(f.y - 25, screen.y),
            w = math.min(f.w + 50, screen.w - (f.x - screen.x)),
            h = math.min(f.h + 50, screen.h - (f.y - screen.y))
        })
    end, false)()
end

local function smallerWindow()
    return windowOperation(function(win)
        local f = win:frame()
        if f.w > 100 and f.h > 100 then  -- Don't make windows too small
            win:setFrame({
                x = f.x + 25,
                y = f.y + 25,
                w = f.w - 50,
                h = f.h - 50
            })
        end
    end, false)()
end

local function nextScreen()
    return windowOperation(function(win) win:moveToScreen(win:screen():next()) end, false)()
end

local function prevScreen()
    return windowOperation(function(win) win:moveToScreen(win:screen():previous()) end, false)()
end

-- App window cycling (simplified)
local function cycleAppWindows()
    local win = hs.window.focusedWindow()
    if not win then
        hs.alert.show("No focused window")
        return true
    end
    
    local app = win:application()
    if not app then
        hs.alert.show("No application found")
        return true
    end
    
    local windows = app:allWindows()
    if #windows <= 1 then
        hs.alert.show("Only one window for this app")
        return true
    end
    
    -- Focus next window in the app
    for i, w in ipairs(windows) do
        if w:id() == win:id() and i < #windows then
            if windows[i+1]:isMinimized() then
                windows[i+1]:unminimize()
            end
            windows[i+1]:focus()
            return true
        end
    end
    
    -- Wrap around to first window
    if windows[1]:isMinimized() then
        windows[1]:unminimize()
    end
    windows[1]:focus()
    return true
end

-- Mouse warping
local function mouseToWindow()
    local win = hs.window.focusedWindow()
    if not win then
        hs.alert.show("No focused window")
        return true
    end
    
    local frame = win:frame()
    hs.mouse.absolutePosition({
        x = frame.x + frame.w/2,
        y = frame.y + frame.h/2
    })
    
    return true
end

-- Grid selector
local function toggleGridSelector()
    local win = hs.window.focusedWindow()
    if not win then
        hs.alert.show("No focused window")
        return true
    end
    
    hs.grid.show(win)
    return true
end

-- Number overlay window focus (simplified)
local function hideWindowOverlays()
    for _, overlay in pairs(windowOverlays) do
        if overlay and overlay.canvas then 
            overlay.canvas:delete() 
        end
        if overlay and overlay.hotkey then 
            overlay.hotkey:delete() 
        end
    end
    
    if windowOverlays.escape then
        windowOverlays.escape:delete()
    end
    
    windowOverlays = {}
    showingOverlays = false
end

local function showWindowOverlays()
    if showingOverlays then
        hideWindowOverlays()
        return true
    end
    
    -- Performance optimization: Get only visible application windows
    local visibleApps = {}
    local allWindows = {}
    
    -- First collect all visible applications (much faster than processing all running apps)
    for _, win in ipairs(hs.window.allWindows()) do
        local app = win:application()
        if app and not visibleApps[app:pid()] then
            visibleApps[app:pid()] = app
        end
    end
    
    -- Then get all windows including minimized ones from visible applications only
    for _, app in pairs(visibleApps) do
        for _, win in ipairs(app:allWindows()) do
            if win:isStandard() then
                table.insert(allWindows, win)
            end
        end
    end
    
    if #allWindows == 0 then
        hs.alert.show("No windows found")
        return true
    end
    
    -- Simplified sorting: visible first, then by app name
    table.sort(allWindows, function(a, b)
        -- First prioritize visibility
        if a:isVisible() and not b:isVisible() then return true end
        if not a:isVisible() and b:isVisible() then return false end
        
        -- Then by app name
        local appA = a:application():name() or ""
        local appB = b:application():name() or ""
        return appA < appB
    end)
    
    -- Create overlays (maximum of 9)
    local count = math.min(#allWindows, 9)
    for i = 1, count do
        local win = allWindows[i]
        local frame = win:frame()
        if frame then
            local isMinimized = win:isMinimized()
            local appName = win:application():name() or "Unknown"
            
            -- Simplified canvas creation with fewer elements
            local canvas = hs.canvas.new({
                x = frame.x + frame.w/2 - 35,
                y = frame.y + frame.h/2 - 35,
                w = 70,
                h = 70
            })
            
            canvas:appendElements({
                {
                    type = "rectangle",
                    action = "fill",
                    fillColor = isMinimized 
                        and {red = 0.3, green = 0.3, blue = 0.3, alpha = 0.8}
                        or {red = 0, green = 0, blue = 0, alpha = 0.8},
                    strokeColor = {white = 1, alpha = 0.9},
                    strokeWidth = 2,
                    roundedRectRadii = {xRadius = 10, yRadius = 10}
                },
                {
                    type = "text",
                    text = tostring(i),
                    textSize = 48,
                    textColor = {white = 1, alpha = 1},
                    textAlignment = "center"
                },
                {
                    type = "text",
                    text = appName,
                    textSize = 10,
                    textColor = {white = 1, alpha = 0.9},
                    textAlignment = "center",
                    frame = {x = 0, y = 45, w = 70, h = 20}
                }
            })
            
            canvas:show()
            
            -- Store the actual window object to avoid issues with window IDs
            windowOverlays[i] = {
                canvas = canvas,
                window = win
            }
            
            -- Create hotkey right away with direct reference to the window (closure)
            local capturedWin = win
            windowOverlays[i].hotkey = hs.hotkey.bind({}, tostring(i), function()
                hideWindowOverlays()
                if capturedWin then
                    if capturedWin:isMinimized() then
                        capturedWin:unminimize()
                        -- Brief delay to ensure window is fully unminimized before focusing
                        hs.timer.doAfter(0.1, function()
                            capturedWin:focus()
                        end)
                    else
                        capturedWin:focus()
                    end
                end
            end)
        end
    end
    
    windowOverlays.escape = hs.hotkey.bind({}, "escape", hideWindowOverlays)
    showingOverlays = true
    
    hs.timer.doAfter(5, function()
        if showingOverlays then hideWindowOverlays() end
    end)
    
    return true
end

-- Define window management mappings
local windowMappings = {
    -- Main positions
    h = { action = moveWindowLeft, desc = "Left Half" },
    j = { action = moveWindowBottom, desc = "Bottom Half" },
    k = { action = moveWindowTop, desc = "Top Half" },
    l = { action = moveWindowRight, desc = "Right Half" },
    
    -- Corners
    u = { action = moveWindowTopLeft, desc = "Top Left Quarter" },
    i = { action = moveWindowTopRight, desc = "Top Right Quarter" },
    n = { action = moveWindowBottomLeft, desc = "Bottom Left Quarter" },
    m = { action = moveWindowBottomRight, desc = "Bottom Right Quarter" },
    
    -- Thirds
    ["1"] = { action = moveWindowLeftThird, desc = "Left Third" },
    ["2"] = { action = moveWindowMiddleThird, desc = "Middle Third" },
    ["3"] = { action = moveWindowRightThird, desc = "Right Third" },
    
    -- Full screen and center
    f = { action = fullScreenWindow, desc = "Full Screen" },
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

-- Create the modal module
local modal = modals.createModalModule(
    windowMappings,
    windowModal.title,
    windowModal,
    "window"
)

return modal 