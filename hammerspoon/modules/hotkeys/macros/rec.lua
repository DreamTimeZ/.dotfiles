local M = {}

local binary = os.getenv("HOME") .. "/.local/bin/rec"
local binaryAvailable = hs.fs.attributes(binary, "mode") ~= nil

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

local function spawn(args, callback)
    if not binaryAvailable then
        hs.alert.show("rec: binary not found at " .. binary)
        return
    end
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
    -- pid-file write window.
    if not binaryAvailable then return false end
    local _, success = hs.execute("'" .. binary .. "' status", false)
    return success
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
