-- Mic mute toggle for the default input device.
-- Brief HUD alert confirms the new state. No menubar indicator.

local M = {}

local ALERT_DURATION = 0.6

function M.toggle()
    local device = hs.audiodevice.defaultInputDevice()
    if not device then
        hs.alert.show("No input device available", ALERT_DURATION)
        return
    end

    device:setInputMuted(not device:inputMuted())
    -- Read-back: setInputMuted silently no-ops on devices without mute support.
    -- Reading post-write keeps the alert truthful for those cases.
    local actual = device:inputMuted()
    hs.alert.show(actual and "Mic Muted" or "Mic On", ALERT_DURATION)
end

return M
