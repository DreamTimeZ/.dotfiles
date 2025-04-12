-- Module for opening websites using a modal

local utils = require("modules.hotkeys.utils")
local config = require("modules.hotkeys.config")
local M = {}

-- Create modal with the websites configuration
local modal = utils.setupModal(config.websites, "Websites:", "url")

-- Public API
function M.enter()
    modal:enter()
end

function M.exit()
    modal:exit()
    hs.alert.closeAll()
end

return M