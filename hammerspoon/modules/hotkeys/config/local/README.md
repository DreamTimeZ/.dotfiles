# Local Hotkey Mappings

Private mapping overrides, symlinked from `~/.dotfiles-private` and git-ignored. The defaults they replace are listed in the [Hammerspoon README](../../../../README.md).

## Files

`<modal>_mappings.lua` returns a table of mappings for that modal in `config.modals`:

| File | Modal | Mapping field |
|------|-------|---------------|
| `apps_mappings.lua` | Apps (Hyper+A) | `app` |
| `finder_mappings.lua` | Finder (Hyper+F) | `path` |
| `websites_mappings.lua` | Websites (Hyper+W) | `url` |
| `settings_mappings.lua` | Settings (Hyper+S) | `pref` |
| `routines_mappings.lua` | Routines (Hyper+R) | `steps` (for `runSteps`) |
| `global_shortcuts_mappings.lua` | Global Hyper shortcuts | a list of entries like `config.globalShortcuts`, not keyed by letter |

A non-empty file **replaces** the defaults entirely, it does not merge, so list every key you want. A file that fails to load or returns an empty table leaves the defaults in place. Custom modals (System, Window, Macros) never read `<modal>_mappings.lua` files: Macros takes its keys from `config/macros_mappings.lua`. The recording macro reads its settings from `rec_config.lua` here.

```lua
-- apps_mappings.lua
return {
    a = { app = "Obsidian", desc = "Obsidian" },
    d = { app = "Discord",  desc = "Discord" },
}
```

After editing, reload with Hyper+D then h. For debug output, run `require("modules.hotkeys").setLogLevel(4)` in the Hammerspoon console (keep `level = 1` in `config.lua`).
