local M = {}

-- Configuration
local config = {
    interval = 0.01,
}

-- State
local timer = nil
local isRunning = false

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
end

--- Stops the auto-clicker
function M.stop()
    if not isRunning or not timer then return end

    timer:stop()
    timer = nil
    isRunning = false
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
end

return M
