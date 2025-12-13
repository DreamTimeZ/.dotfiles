# iTerm2 Configuration

This document outlines the recommended iTerm2 settings for optimal terminal usage.

## Hotkey Settings

- Create a Dedicated Hotkey Window: `control + cmd + enter`
- Show/hide all windows with a system-wide hotkey: `control + shift + cmd + enter`

## General Settings

### Closing

- Uncheck "Confirm 'Quit iTerm2 (`cmd + q`)'"

### Selection

- Check "Applications in terminal max access clipboard"

## Profile Settings

### Default Profile

#### Window (Default)

- Columns: 122
- Rows: 29
  > Note: These values are optimized for quarter window snapping. Adjust based on your window manager settings.

#### Colors

Use your preferred color scheme (e.g., Solarized, Dracula, Nord).

#### Key Mappings

1. Select "Natural Text Editing" preset
2. Add the following custom mappings:
   - `opt + delete` → Send Hex Codes: `0x17`
   - `cmd + delete` → Send Hex Codes: `0x1b 0x5b 0x37 0x39 0x7e`
   - `fn + cmd + delete` → Send Hex Codes: `0x1b 0x5b 0x39 0x39 0x7e`

### Hotkey Profile

#### Window (Hotkey)

- Text → Font: MesloLGS NF
- Colors: Use your preferred color scheme
- Keys → Key Mappings → Presets: "Natural Text Editing"

#### Terminal

- Notifications → Silence bell: Checked
  > This disables the beep/bell sound in iTerm2. [Source](https://superuser.com/questions/1680502/how-do-i-disable-the-beep-bell-sound-in-iterm2-in-macbook)
