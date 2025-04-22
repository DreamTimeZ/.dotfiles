-- Local mappings for the 'finder' modal
-- This file overrides the default mappings in config.modals.finder.mappings
-- Each mapping must have a 'path' field that matches the handler.field in the modal definition
return {
    d = { path = os.getenv("HOME") .. "/Downloads",                         desc = "Downloads" },
    s = { path = os.getenv("HOME") .. "/Documents/Studies",                 desc = "Studies" },
    a = { path = os.getenv("HOME") .. "/Documents/Studies/Audio/processed", desc = "Studies Audios" },
} 