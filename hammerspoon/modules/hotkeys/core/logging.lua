-- Production-grade logging system for hotkeys module
-- Follows industry best practices for performance, security, and maintainability
local M = {}

-- Cache config reference to avoid redundant requires
local config = require("modules.hotkeys.config.config")

-- Rate limiting state
local rateLimitState = {
    messageCount = 0,
    windowStart = 0
}

-- Sanitize log message to prevent injection and limit length
local function sanitizeMessage(message)
    if type(message) ~= "string" then
        message = tostring(message)
    end
    
    -- Remove potential control characters and limit length
    message = message:gsub("[\x00-\x1f\x7f-\x9f]", "")
    
    if #message > config.logging.maxMessageLength then
        message = message:sub(1, config.logging.maxMessageLength - 3) .. "..."
    end
    
    return message
end

-- Check rate limiting
local function checkRateLimit()
    if not config.logging.rateLimiting.enabled then
        return true
    end
    
    local now = os.time() * 1000 -- Convert to milliseconds
    
    -- Reset window if expired
    if now - rateLimitState.windowStart >= config.logging.rateLimiting.windowMs then
        rateLimitState.messageCount = 0
        rateLimitState.windowStart = now
    end
    
    -- Check if we're within rate limit
    if rateLimitState.messageCount >= config.logging.rateLimiting.maxPerSecond then
        return false
    end
    
    rateLimitState.messageCount = rateLimitState.messageCount + 1
    return true
end

-- Core logging function with production-grade features
function M.log(level, message, context)
    -- Early return for performance (most common case in production)
    if not config.logging.enabled or level > config.logging.level then 
        return 
    end
    
    -- Rate limiting protection
    if not checkRateLimit() then
        return
    end
    
    -- Sanitize input for security
    message = sanitizeMessage(message)
    
    local levelName = config.logging.levelNames[level] or "UNKNOWN"
    local logParts = {}
    
    -- Build log message components
    if config.logging.includeTimestamp then
        table.insert(logParts, os.date("%Y-%m-%d %H:%M:%S"))
    end
    
    if config.logging.includeLevel then
        table.insert(logParts, levelName)
    end
    
    table.insert(logParts, "[Hotkeys]")
    table.insert(logParts, message)
    
    -- Add context only if enabled and provided
    if config.logging.includeContext and context then
        table.insert(logParts, "(" .. sanitizeMessage(tostring(context)) .. ")")
    end
    
    -- Output log message
    local logMessage = table.concat(logParts, " ")
    
    -- Use pcall to prevent logging errors from crashing the application
    local success, err = pcall(print, logMessage)
    if not success then
        -- Fallback: try to log the logging error itself
        pcall(print, "[Hotkeys ERROR] Logging failure: " .. tostring(err))
    end
end

-- Performance-optimized log function creators
local function createLogFunction(level)
    local levelValue = config.logging.LEVELS[level]
    return function(message, context)
        -- Inline the most common checks for maximum performance
        if config.logging.enabled and levelValue <= config.logging.level then
            M.log(levelValue, message, context)
        end
    end
end

-- Generate all logging functions
M.error = createLogFunction("ERROR")
M.warn = createLogFunction("WARN") 
M.info = createLogFunction("INFO")
M.debug = createLogFunction("DEBUG")

-- Production-safe configuration functions
function M.setLogLevel(level)
    local newLevel
    
    if type(level) == "string" and config.logging.LEVELS[level] then
        newLevel = config.logging.LEVELS[level]
    elseif type(level) == "number" and level >= 1 and level <= 4 then
        newLevel = level
    else
        M.error("Invalid log level: " .. tostring(level))
        return false
    end
    
    local oldLevel = config.logging.level
    config.logging.level = newLevel
    M.warn("Log level changed from " .. oldLevel .. " to " .. newLevel)
    return true
end

function M.setLoggingEnabled(enabled)
    if type(enabled) ~= "boolean" then
        M.error("setLoggingEnabled requires boolean parameter")
        return false
    end
    
    local oldState = config.logging.enabled
    config.logging.enabled = enabled
    
    if oldState ~= enabled then
        local message = enabled and "Logging enabled" or "Logging disabled" 
        M.warn(message)
    end
    
    return true
end

-- Production monitoring functions
function M.getLogStats()
    return {
        enabled = config.logging.enabled,
        level = config.logging.level,
        levelName = config.logging.levelNames[config.logging.level],
        rateLimitHits = rateLimitState.messageCount,
        rateLimitEnabled = config.logging.rateLimiting.enabled
    }
end

function M.resetRateLimit()
    rateLimitState.messageCount = 0
    rateLimitState.windowStart = 0
    M.warn("Rate limit state reset")
end

return M 