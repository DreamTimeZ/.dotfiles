# Hotkeys Module

Config-driven Hyper hotkeys and modals. Bindings are listed in the [Hammerspoon README](../../README.md).

```text
hotkeys/
├── init.lua            Loads every modal in config.modals, binds config.globalShortcuts, returns the API
├── config/
│   ├── init.lua        What require("modules.hotkeys.config") loads
│   ├── config.lua      Modals, global shortcuts, logging, delays
│   ├── macros_mappings.lua
│   └── local/          Private mapping overrides (git-ignored)
├── core/               actions.lua (handlers), modals.lua, logging.lua, validation.lua
├── modals/             Custom modals: system, window, macros
├── macros/             auto-clicker, natural-scroll, rec
└── ui/ui.lua
```

## Adding a Modal

1. Add an entry to `config.modals` in `config/config.lua`:

    ```lua
    config.modals.newmodal = {
        title = "My New Modal:",
        handler = {
            field = "myfield",    -- field every mapping must have
            action = "openURL"    -- handler that receives mapping[field]
        },
        mappings = {
            a = { myfield = "https://example.com", desc = "Example" },
        }
    }
    ```

2. Bind it in `config.globalShortcuts`: `{ key = "x", modal = "newmodal", desc = "New Modal" }`. Without this entry the modal loads but nothing opens it.

`handler.action` names a key of `ACTION_HANDLERS` in `core/actions.lua`: `launchOrFocus`, `launchGhosttyTransparent`, `openURL`, `openFinderFolder`, `openSystemPreferencePane`, `clearNotifications`, `functionCall`, `runSteps`. To add one, write the function in `actions.lua` and register it there.

For behavior beyond one handler per modal, set `customModule = "modules.hotkeys.modals.<name>"` and build the module with `modals.createModalModule(mappings, title, modal, name)`, as `modals/system.lua` does. Custom modals ignore `config/local/` mappings.

## Global Shortcuts

Each `config.globalShortcuts` entry has a `key` (name or keycode) and one of:

- `modal = "<name>"`: open a modal
- `handler` + `mapping`: run an action handler directly
- `fn`: call a function

Modifiers default to Hyper. `mods = {}` binds the bare key. A non-empty `config/local/global_shortcuts_mappings.lua` replaces the whole list, `config/local/global_extra_mappings.lua` appends to it. An entry that reuses the key combination of an earlier entry is skipped and logged as an error.

## API

`require("modules.hotkeys")` returns `exitAllModals()`, `setLogLevel(level)`, `setLoggingEnabled(enabled)`, `createModal(name)`, `executeAction(handler, mapping)`, `reloadConfig()`.
