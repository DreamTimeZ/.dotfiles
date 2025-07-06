local M = {}

-- Configuration
local config = {
    interval = 2.8,        -- Click interval in seconds
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

--- Performs a single left click at current mouse position
function M.click()
    hs.eventtap.leftClick(hs.mouse.absolutePosition())
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