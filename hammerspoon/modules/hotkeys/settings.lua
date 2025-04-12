-- Module for opening system settings using a modal

local utils = require("modules.hotkeys.utils")
local config = require("modules.hotkeys.config")
local M = {}

-- Create modal with the settings configuration
local modal = utils.setupModal(config.settings, "System Settings:", "pref")

-- Public API
function M.enter()
    modal:enter()
end

function M.exit()
    modal:exit()
    hs.alert.closeAll()
end

return M