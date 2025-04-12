# Hammerspoon Configuration

## Overview

Hammerspoon is a powerful automation tool for macOS that allows for extensive customization and control of your system through Lua scripting.

## Features

- **Window Management**: Resize and position windows with hotkeys
- **Application Switching**: Quickly launch or focus applications
- **Custom Configurations**: Extensible with Lua scripting
- **System Monitoring**: Monitor and react to system events

## Hotkey System

The configuration uses Hyper key (⌘+⌃+⌥+⇧) as the main modifier, mapped via Karabiner-Elements from Caps Lock.

### Primary Hotkeys

| Hotkey | Action | Description |
|--------|--------|-------------|
| Hyper + A | Open Apps Modal | Select from various applications |
| Hyper + F | Open Finder Modal | Quick access to common folders |
| Hyper + W | Open Websites Modal | Open frequently used websites |
| Hyper + D | Open System Modal | Perform system actions |
| Hyper + S | Open Settings Modal | Quick access to system settings |
| Hyper + Return | Open iTerm2 | Directly launch or focus terminal |

### App Shortcuts (Hyper+A, then...)

Items appear in alphabetical order in the modal:

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

### Finder Shortcuts (Hyper+F, then...)

Items appear in alphabetical order in the modal:

| Key | Location |
|-----|----------|
| a | Applications |
| c | Documents |
| d | Desktop |
| f | Downloads |
| h | Home |
| i | iCloud |
| l | Library |
| m | Music |
| p | Pictures |
| u | Utilities |
| v | Movies |

### Website Shortcuts (Hyper+W, then...)

Items appear in alphabetical order in the modal:

| Key | Website |
|-----|---------|
| a | Apple |
| g | GitHub |
| m | Google Maps |
| n | Netflix |
| r | Reddit |
| s | Stack Overflow |
| w | Wikipedia |
| y | YouTube |

### System Actions (Hyper+D, then...)

Items appear in alphabetical order in the modal:

| Key | Action |
|-----|--------|
| c | Clear Notifications |
| h | Reload Hammerspoon |
| r | Restart System (with confirmation) |
| s | Shutdown System (with confirmation) |

### Settings Shortcuts (Hyper+S, then...)

Items appear in alphabetical order in the modal:

| Key | System Setting |
|-----|----------------|
| b | Bluetooth |
| w | Wi-Fi |
| u | Software Update |
| p | Security & Privacy |
| d | Displays |

## Customization

All hotkey mappings can be customized in the following locations:

- Global configuration: `~/.hammerspoon/modules/hotkeys/config.lua`
- Local (user-specific) mappings: `~/.hammerspoon/modules/hotkeys/local/*.lua`

See the README in the `local` directory for detailed customization instructions.

## Installation

```bash
# Install Hammerspoon via Homebrew
brew install --cask hammerspoon

# Link configuration
ln -sf ~/.dotfiles/hammerspoon ~/.hammerspoon

# Note: Ensure the init.lua is directly in ~/.hammerspoon
# If not, you may need to remove the existing directory:
# rm -rf ~/.hammerspoon && ln -s ~/.dotfiles/hammerspoon ~/.hammerspoon
```
