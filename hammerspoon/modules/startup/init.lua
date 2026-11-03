-- Hide specific apps on boot so they launch silently as background processes.
-- Only active during a grace period after system boot to avoid interfering
-- with normal app usage during the session.

local M = {}

local BOOT_GRACE_PERIOD_SECONDS = 300

local bootTimeSec = hs.execute("sysctl -n kern.boottime"):match("sec = (%d+)")
local bootTime = tonumber(bootTimeSec)

local function isBootPhase()
  return bootTime and (os.time() - bootTime) < BOOT_GRACE_PERIOD_SECONDS
end

local appsToHide = { "Todoist" }

if isBootPhase() then
  -- Hide apps that launched before Hammerspoon
  for _, appName in ipairs(appsToHide) do
    local app = hs.application.find(appName)
    if app then app:hide() end
  end

  -- Hide apps that launch after Hammerspoon
  local filters = {}
  for _, appName in ipairs(appsToHide) do
    filters[#filters + 1] = hs.window.filter.new(appName)
      :subscribe(hs.window.filter.windowCreated, function(window)
        if window and isBootPhase() then
          window:application():hide()
        end
      end)
  end

  -- A subscribed filter keeps window.filter's global watcher (AX observers on every app and
  -- window) running until unsubscribed. Held in M so the timer survives garbage collection.
  M.graceEndTimer = hs.timer.doAfter(BOOT_GRACE_PERIOD_SECONDS - (os.time() - bootTime), function()
    for _, filter in ipairs(filters) do filter:unsubscribeAll() end
  end)
end

return M
