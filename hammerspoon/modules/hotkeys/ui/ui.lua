-- UI helpers for hotkeys module
local M = {}

-- Cache dependencies
local config = require("modules.hotkeys.config")

-- UI helpers
function M.showFormattedAlert(content, title, options)
    options = options or {}
    
    -- Initialize result array with pre-allocated capacity to avoid resizing
    local formattedLines = title and {title} or {}
    
    -- Cache config value for performance
    local maxItemsPerLine = options.maxItemsPerLine or config.ui.maxItemsPerLine
    
    -- If content is already a formatted array, use it directly but respect maxItemsPerLine
    if type(content) == "table" and #content > 0 and type(content[1]) == "string" then
        -- Process formatted key hints in batches according to maxItemsPerLine
        local lineItems = {}
        local totalItems = #content
        
        for i, item in ipairs(content) do
            table.insert(lineItems, item)
            
            -- Flush line when full or at the end
            if #lineItems >= maxItemsPerLine or i == totalItems then
                table.insert(formattedLines, table.concat(lineItems, "   "))
                lineItems = {}
            end
        end
    else
        -- Handle string or table content
        local items = type(content) == "table" and content or {tostring(content)}
        
        -- Format items into lines with maximum items per line
        if #items > 0 then
            local lineItems = {}
            local totalItems = #items
            
            for i, item in ipairs(items) do
                table.insert(lineItems, item)
                
                -- Flush line when full or at the end
                if #lineItems >= maxItemsPerLine or i == totalItems then
                    table.insert(formattedLines, table.concat(lineItems, "   "))
                    lineItems = {}
                end
            end
        end
    end
    
    -- Show the alert with all combined lines
    hs.alert.show(table.concat(formattedLines, "\n"), options)
end

return M 