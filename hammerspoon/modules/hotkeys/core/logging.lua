-- Logging functionality for hotkeys module
local M = {}

-- Cache config reference to avoid redundant requires
local config = require("modules.hotkeys.config.config")

-- Log a message at the specified level with minimal overhead
function M.log(level, message)
    -- Check if logging is enabled and level is appropriate
    if not config.logging.enabled or level > config.logging.level then return end
    
    local levelName = config.logging.levelNames[level] or "UNKNOWN"
    local timestamp = os.date("%H:%M:%S")
    
    -- Use string format instead of concatenation for better performance
    print(string.format("[Hotkeys %s %s] %s", levelName, timestamp, message))
end

local function createLogFunction(level)
    local levelValue = config.logging.LEVELS[level]
    return function(message)
        if config.logging.enabled and levelValue <= config.logging.level then
            M.log(levelValue, message)
        end
    end
end

-- Generate all logging functions at once
M.error = createLogFunction("ERROR")
M.warn = createLogFunction("WARN")
M.info = createLogFunction("INFO")
M.debug = createLogFunction("DEBUG")

-- Set the logging level
function M.setLogLevel(level)
    if type(level) == "string" and config.logging.LEVELS[level] then
        config.logging.level = config.logging.LEVELS[level]
    elseif type(level) == "number" and level >= 0 and level <= 4 then
        config.logging.level = level
    else
        M.error("Invalid log level: " .. tostring(level))
    end
end

-- Enable or disable logging entirely
function M.setLoggingEnabled(enabled)
    config.logging.enabled = enabled
end

return M 