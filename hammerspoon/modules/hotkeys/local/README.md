# Local Hotkey Mappings

This directory contains local hotkey mappings that are not included in git. You can customize these files to add your own personal hotkeys without affecting the shared configuration.

## Available Mapping Files

- `apps_mappings.lua`: Custom application mappings
- `websites_mappings.lua`: Custom website mappings
- `finder_mappings.lua`: Custom Finder folder mappings

## How to Use

1. Edit the appropriate mapping file in this directory
2. Add your own mappings
3. Reload Hammerspoon configuration (Cmd+Alt+Ctrl+R or via the menu bar)

**Important**: If a local mapping file exists and contains mappings, it will **completely replace** the default mappings. This means you need to define all the hotkeys you want to use in your local files.

## Default Mappings

If you don't have local mapping files, the following default mappings will be used. You can use these as a starting point for your custom mappings.

### Default Application Mappings (in apps.lua)

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

### Default Website Mappings (in websites.lua)

| Key | URL | Description |
|-----|-----|-------------|
| a   | `https://www.apple.com/` | Apple |
| g   | `https://www.google.com/` | Google |
| m   | `https://www.google.com/maps` | Google Maps |
| n   | `https://www.netflix.com/` | Netflix |
| r   | `https://www.reddit.com/` | Reddit |
| t   | `https://translate.google.com/` | Translate |
| w   | `https://en.wikipedia.org/` | Wikipedia |
| y   | `https://www.youtube.com/` | YouTube |

### Default Finder Folder Mappings (in finder.lua)

| Key | Path | Description |
|-----|------|-------------|
| a   | ~/Applications | Applications |
| d   | ~/Desktop | Desktop |
| o   | ~/Documents | Documents |
| w   | ~/Downloads | Downloads |
| m   | ~/Movies | Movies |
| u   | ~/Music | Music |
| p   | ~/Pictures | Pictures |
| h   | ~ | Home |

## Examples

### Custom Application Mappings

In `apps_mappings.lua`:

```lua
return {
    a = { app = "Obsidian",              desc = "Obsidian" },
    -- Add all the applications you want to use
}
```

### Custom Website Mappings

In `websites_mappings.lua`:

```lua
return {
    y = { url = "https://www.youtube.com/", desc = "YouTube" },
    -- Add all the websites you want to use
}
```

### Custom Finder Folder Mappings

In `finder_mappings.lua`:

```lua
return {
    d = { path = os.getenv("HOME") .. "/Downloads", desc = "Downloads" },
    -- Add all the folders you want to use
}
```

## Robustness Features

The mapping system includes several robustness features:

1. **Mapping Validation**: Each mapping is validated to ensure it contains the required fields.
2. **Error Handling**: Corrupted or invalid mappings are filtered out.
3. **Path Existence Checks**: Finder paths are checked for existence (with warnings).
4. **Debugging Capabilities**: Enable debug mode in `init.lua` to troubleshoot issues.
5. **Fallback Mechanism**: If local mappings cause errors, the system falls back to defaults.

## Enabling Debug Mode

To troubleshoot issues, you can enable debug mode by uncommenting this line in `init.lua`:

```lua
-- utils.setDebug(true)
```

Debug messages will appear in the Hammerspoon console (accessible via the Hammerspoon menu bar icon).
