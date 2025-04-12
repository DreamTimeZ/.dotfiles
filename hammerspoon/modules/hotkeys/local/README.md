# Local Hotkey Mappings

This directory contains local hotkey mappings that are not included in git. You can customize these files to add your own personal hotkeys without affecting the shared configuration.

## Available Mapping Files

- `apps_mappings.lua`: Custom application mappings
- `websites_mappings.lua`: Custom website mappings
- `finder_mappings.lua`: Custom Finder folder mappings
- `settings_mappings.lua`: Custom System Settings mappings
- Add custom ones (add them also in the config e.g. `config.settings = ...`)

## How to Use

1. Create or edit the appropriate mapping file in this directory
2. Add your own mappings following the examples below
3. Reload Hammerspoon configuration (Hyper+R or via the menu bar)

**Important**: If a local mapping file exists and contains mappings, it will **completely replace** the default mappings. This means you need to define all the hotkeys you want to use in your local files.

## Default Mappings

If you don't have local mapping files, the following default mappings will be used. You can use these as a starting point for your custom mappings.

### Default Application Mappings (in config.lua)

| Key | Application | Description |
|-----|-------------|-------------|
| a   | App Store   | App Store   |
| b   | Books       | Books       |
| c   | Calendar    | Calendar    |
| f   | FaceTime    | FaceTime    |
| h   | Photos      | Photos      |
| m   | Mail        | Mail        |
| n   | Notes       | Notes       |
| o   | Maps        | Maps        |
| p   | Preview     | Preview     |
| r   | Reminders   | Reminders   |
| s   | Safari      | Safari      |
| t   | Terminal    | Terminal    |
| u   | Music       | Music       |
| v   | QuickTime Player | QuickTime |
| w   | Weather     | Weather     |
| x   | Calculator  | Calculator  |
| z   | System Settings | Settings |

### Default Finder Folder Mappings (in config.lua)

| Key | Path | Description |
|-----|------|-------------|
| a   | ~/Applications | Applications |
| d   | ~/Desktop | Desktop |
| c   | ~/Documents | Documents |
| f   | ~/Downloads | Downloads |
| h   | ~ | Home |
| p   | ~/Pictures | Pictures |
| m   | ~/Music | Music |
| v   | ~/Movies | Movies |
| l   | ~/Library | Library |
| u   | /Utilities | Utilities |
| i   | ~/Library/CloudStorage/iCloud Drive | iCloud |

### Default Website Mappings (in config.lua)

| Key | URL | Description |
|-----|-----|-------------|
| a   | `https://www.apple.com` | Apple |
| g   | `https://github.com` | GitHub |
| m   | `https://maps.google.com` | Maps |
| n   | `https://www.netflix.com` | Netflix |
| r   | `https://www.reddit.com` | Reddit |
| s   | `https://www.stackoverflow.com` | Stack Overflow |
| w   | `https://www.wikipedia.orm` | Wikipedia |
| y   | `https://www.youtube.com` | YouTube |

### Default System Settings Mappings (in config.lua)

| Key | System Setting |
|-----|----------------|
| b | Bluetooth |
| w | Wi-Fi |
| u | Software Update |
| p | Security & Privacy |
| d | Displays |

## Examples

### Custom Application Mappings

In `apps_mappings.lua`:

```lua
return {
    a = { app = "Obsidian",              desc = "Obsidian" },
    d = { app = "Discord",               desc = "Discord" },
    f = { app = "Firefox",               desc = "Firefox" },
    -- Add all the applications you want to use
}
```

### Custom Website Mappings

In `websites_mappings.lua`:

```lua
return {
    g = { url = "https://github.com",        desc = "GitHub" },
    y = { url = "https://www.youtube.com",   desc = "YouTube" },
    -- Add all the websites you want to use
}
```

### Custom Finder Folder Mappings

In `finder_mappings.lua`:

```lua
return {
    d = { path = "~/Downloads",    desc = "Downloads" },
    p = { path = "~/Projects",     desc = "Projects" },
    -- Add all the folders you want to use
}
```

## Robustness Features

The mapping system includes several robustness features:

1. **Mapping Validation**: Each mapping is validated to ensure it contains the required fields
2. **Error Handling**: Corrupted or invalid mappings are filtered out
3. **Path Existence Checks**: Finder paths are checked for existence (with warnings)
4. **Debugging Capabilities**: Enable debug mode in config.lua to troubleshoot issues
5. **Fallback Mechanism**: If local mappings cause errors, the system falls back to defaults
6. **Sorted Alerts**: Items in alerts are displayed alphabetically by description

## Enabling Debug Mode

To troubleshoot issues, you can enable debug mode by editing `config.lua`:

```lua
-- Debug settings
config.debug = true
```

Debug messages will appear in the Hammerspoon console (accessible via the Hammerspoon menu bar icon).
