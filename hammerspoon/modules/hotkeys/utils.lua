-- Utility functions for launching/focusing apps, opening folders, URLs, etc.
local M = {}

function M.launchOrFocus(appName)
    hs.application.launchOrFocus(appName)
    hs.timer.doAfter(0.1, function()
        local app = hs.application.get(appName)
        if app then app:activate() end
    end)
end

function M.openFinderFolder(path)
    hs.execute("open " .. path)
end

function M.openURL(url)
    hs.urlevent.openURL(url)
end

function M.openSystemPreferencePane(url)
    -- Force-quit System Preferences so that it reopens fresh.
    hs.execute("killall 'System Preferences'")
    -- Wait 0.5 seconds for it to quit completely, then open the given URL.
    hs.timer.doAfter(0.5, function()
        hs.execute("open \"" .. url .. "\"")
    end)
end

function M.clearNotifications()
    hs.execute("killall NotificationCenter")
end

return M