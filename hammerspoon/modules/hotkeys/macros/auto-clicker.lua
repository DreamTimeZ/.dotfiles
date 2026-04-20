local M = {}

-- Configuration
local config = {
    interval = 0.1,      -- Click interval in seconds (10 clicks/sec; browser-safe)
    showAlerts = true    -- Whether to show status alerts
}

-- State
local timer = nil
local isRunning = false

--- Shows a status alert if enabled
local function showAlert(message)
    if config.showAlerts then
        hs.alert.show("Auto-Clicker: " .. message)
    end
end

--- Performs a single left click at current mouse position.
--- Posts mousedown+mouseup back-to-back rather than using
--- hs.eventtap.leftClick, which sleeps 200ms between events and causes the
--- cursor to snap if the user is moving the mouse during that window.
--- Forces click-state = 1 so rapid clicks don't coalesce into
--- double/triple clicks (browsers would otherwise select text or
--- misinterpret them as multi-click gestures).
function M.click()
    local event = hs.eventtap.event
    local pos = hs.mouse.absolutePosition()
    local clickStateProp = event.properties.mouseEventClickState
    event.newMouseEvent(event.types.leftMouseDown, pos)
        :setProperty(clickStateProp, 1):post()
    event.newMouseEvent(event.types.leftMouseUp, pos)
        :setProperty(clickStateProp, 1):post()
end

--- Starts the auto-clicker
function M.start()
    if isRunning then return end
    
    timer = hs.timer.doEvery(config.interval, M.click)
    isRunning = true
    showAlert("ON")
end

--- Stops the auto-clicker
function M.stop()
    if not isRunning or not timer then return end
    
    timer:stop()
    timer = nil
    isRunning = false
    showAlert("OFF")
end

--- Toggles the auto-clicker state
function M.toggle()
    if isRunning then
        M.stop()
    else
        M.start()
    end
end

--- Returns current running state
function M.isRunning()
    return isRunning
end

--- Configures the auto-clicker
function M.configure(options)
    if options.interval then config.interval = options.interval end
    if options.showAlerts ~= nil then config.showAlerts = options.showAlerts end
end

return M