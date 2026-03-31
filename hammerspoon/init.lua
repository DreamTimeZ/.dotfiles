-- Main Hammerspoon configuration file

-- Hide login-item apps that should start in the background
require("modules.startup")

-- Load and initialize the hotkeys module.
local hotkeys = require("modules.hotkeys")

-- Access UI helpers directly from the UI module
local ui = require("modules.hotkeys.ui.ui")

ui.showFormattedAlert("Hammerspoon Config Loaded")