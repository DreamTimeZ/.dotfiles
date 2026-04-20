local M = {}

local binary = os.getenv("HOME") .. "/.local/bin/rec"

-- hs.task:setEnvironment REPLACES env (not extends), so inherited vars must
-- be carried forward explicitly. Local config may override or add REC_* vars.
local env = {
    PATH = os.getenv("PATH"),
    HOME = os.getenv("HOME"),
    USER = os.getenv("USER"),
}

local ok, localCfg = pcall(require, "modules.hotkeys.config.local.rec_config")
if ok and type(localCfg) == "table" and type(localCfg.env) == "table" then
    for k, v in pairs(localCfg.env) do env[k] = v end
end

-- Check lazily: if the user installs the binary after Hammerspoon loads,
-- the first call picks it up without needing a config reload.
local function binaryExists()
    return hs.fs.attributes(binary) ~= nil
end

local function spawn(args, callback)
    if not binaryExists() then
        hs.alert.show("rec: binary not found at " .. binary)
        return
    end
    -- hs.task.new(path, callback, args): third arg dispatches on type
    -- (table → arguments, function → streamCallback). Tested in this shape.
    local task = hs.task.new(binary, callback, args)
    task:setEnvironment(env)
    task:start()
end

local function alertFirstLine(fallback)
    return function(_, stdout, stderr)
        local out = (stdout ~= nil and stdout ~= "") and stdout or (stderr or "")
        hs.alert.show("rec: " .. (out:match("[^\r\n]+") or fallback))
    end
end

local function pickTargetAndStart()
    spawn({"targets"}, function(_, stdout, stderr)
        if stdout == nil or stdout == "" then
            local msg = stderr and stderr:match("[^\r\n]+") or "no targets configured"
            hs.alert.show("rec: " .. msg)
            return
        end
        local choices = {}
        for line in stdout:gmatch("[^\r\n]+") do
            table.insert(choices, { text = line })
        end
        if #choices == 0 then
            hs.alert.show("rec: no targets configured")
            return
        end
        local chooser = hs.chooser.new(function(choice)
            if not choice then return end
            spawn({"start", choice.text}, alertFirstLine("start " .. choice.text))
        end)
        chooser:choices(choices)
        chooser:placeholderText("Recording target")
        chooser:show()
    end)
end

function M.isRunning()
    -- Delegate to the script; it owns session-tag verification and orphan
    -- recovery, avoiding PID-reuse false positives and the post-fork
    -- pid-file write window. Uses hs.task argv form (not hs.execute + sh -c)
    -- so the binary path isn't subject to shell quoting rules.
    if not binaryExists() then return false end
    local task = hs.task.new(binary, nil, {"status"})
    task:setEnvironment(env)
    if not task:start() then return false end
    task:waitUntilExit()
    return task:terminationStatus() == 0
end

function M.start() pickTargetAndStart() end

function M.stop() spawn({"stop"}, alertFirstLine("stop")) end

function M.toggle()
    if M.isRunning() then
        M.stop()
    else
        pickTargetAndStart()
    end
end

return M
