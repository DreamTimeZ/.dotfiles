-- Module for opening Finder locations using a modal

local utils = require("modules.hotkeys.utils")
local config = require("modules.hotkeys.config")
local M = {}

-- Create modal with the finder configuration
local modal = utils.setupModal(config.finder, "Finder Locations:", "path")

-- Public API
function M.enter()
    modal:enter()
end

function M.exit()
    modal:exit()
    hs.alert.closeAll()
end

return M