-- Module for launching and focusing apps using a modal

local utils = require("modules.hotkeys.utils")
local config = require("modules.hotkeys.config")
local M = {}

-- Create modal with the apps configuration
local modal = utils.setupModal(config.apps, "Apps:", "app")

-- Public API
function M.enter()
    modal:enter()
end

function M.exit()
    modal:exit()
    hs.alert.closeAll()
end

return M