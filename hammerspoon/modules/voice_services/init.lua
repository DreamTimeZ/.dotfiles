-- VoiceMode's launchd services stay launchctl-disabled so nothing loads at login. A loaded
-- job keeps its KeepAlive restarts while disabled (measured 2026-10-30), which Kokoro's
-- worker recycle every 25 requests relies on.
-- VoiceMode's own `service start`/`restart` (MCP `service` tool, `voicemode whisper model`
-- without --no-restart) uses `launchctl load`, which skips a disabled job: it reports
-- "loaded but not yet listening" and the service stays down until this toggle runs.
-- `service enable` (also run by installs with auto-enable) uses `launchctl load -w`, which
-- clears the disabled state: the service loads at login again until this toggle next runs.

local M = {}

local ALL_LABELS = { "com.voicemode.whisper", "com.voicemode.kokoro", "com.voicemode.mlx-audio" }
local LAUNCH_AGENTS_DIR = os.getenv("HOME") .. "/Library/LaunchAgents/"
local ALERT_DURATION = 1

local function launchctl(args)
  local _, ok = hs.execute("/bin/launchctl " .. args .. " 2>/dev/null")
  return ok == true
end

local function plistPath(label)
  return LAUNCH_AGENTS_DIR .. label .. ".plist"
end

local function installedLabels()
  local labels = {}
  for _, label in ipairs(ALL_LABELS) do
    if hs.fs.attributes(plistPath(label)) then
      table.insert(labels, label)
    end
  end
  return labels
end

function M.toggle()
  local domain = "gui/" .. (hs.execute("/usr/bin/id -u"):gsub("%s+", ""))
  local labels = installedLabels()
  if #labels == 0 then
    hs.alert.show("No Voice Services installed", ALERT_DURATION)
    return
  end

  local running = false
  for _, label in ipairs(labels) do
    if launchctl("print " .. domain .. "/" .. label .. " >/dev/null") then
      running = true
    end
  end

  if running then
    for _, label in ipairs(labels) do
      launchctl("bootout " .. domain .. "/" .. label)
      launchctl("disable " .. domain .. "/" .. label)
    end
    hs.alert.show("Voice Services Off", ALERT_DURATION)
    return
  end

  local failed = {}
  for _, label in ipairs(labels) do
    launchctl("enable " .. domain .. "/" .. label)
    if not launchctl("bootstrap " .. domain .. ' "' .. plistPath(label) .. '"') then
      table.insert(failed, label)
    end
    launchctl("disable " .. domain .. "/" .. label)
  end
  if #failed == 0 then
    hs.alert.show("Voice Services On", ALERT_DURATION)
  else
    hs.alert.show("Voice Services failed: " .. table.concat(failed, ", "), ALERT_DURATION)
  end
end

return M
