-- Main Hammerspoon configuration file

-- Load and initialize the hotkeys module.
local hotkeys = require("modules.hotkeys")

-- Access the utils module through the hotkeys module
local utils = require("modules.hotkeys.utils")

utils.showFormattedAlert("Hammerspoon Config Loaded")