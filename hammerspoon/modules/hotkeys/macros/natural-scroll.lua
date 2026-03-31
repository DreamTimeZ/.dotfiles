local M = {}

local TRACKPAD_PANE = "x-apple.systempreferences:com.apple.Trackpad-Settings.extension"
local SCROLL_TAB_INDEX = 2
local POLL_INTERVAL = 0.1
local TIMEOUT = 5

local APPLESCRIPT = string.format([[
do shell script "open '%s'"

tell application "System Events"
    set deadline to (current date) + %d

    repeat until (exists window 1 of process "System Settings")
        if (current date) > deadline then error "Timed out waiting for System Settings"
        delay %s
    end repeat

    tell process "System Settings"
        set wRef to group 1 of group 3 of splitter group 1 of group 1 of window 1

        repeat until (exists tab group 1 of wRef)
            if (current date) > deadline then error "Timed out waiting for tab group"
            delay %s
        end repeat

        click radio button %d of tab group 1 of wRef

        repeat until (exists checkbox "Natural scrolling" of group 1 of scroll area 1 of wRef)
            if (current date) > deadline then error "Timed out waiting for checkbox"
            delay %s
        end repeat

        set cb to checkbox "Natural scrolling" of group 1 of scroll area 1 of wRef
        perform action "AXPress" of cb
    end tell
end tell

tell application "System Settings" to quit
]], TRACKPAD_PANE, TIMEOUT, POLL_INTERVAL, POLL_INTERVAL, SCROLL_TAB_INDEX, POLL_INTERVAL)

function M.toggle()
    local task = hs.task.new("/usr/bin/osascript", function(code, stdout, stderr)
        if code ~= 0 then
            hs.osascript.applescript('tell application "System Settings" to quit')
            local msg = stderr ~= "" and stderr:gsub("%s+$", "") or "unknown error"
            hs.alert.show("Natural Scroll: failed (" .. msg .. ")")
        end
    end, { "-e", APPLESCRIPT })
    task:start()
end

return M
