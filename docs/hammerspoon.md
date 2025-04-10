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
| Hyper + N | Open System Modal | Perform system actions |
| Hyper + S | Open Settings Modal | Quick access to system preferences |
| Hyper + Return | Open iTerm2 | Directly launch or focus terminal |

### App Shortcuts (Hyper+A, then...)

| Key | Application |
|-----|-------------|
| A | Obsidian |
| C | Cursor |
| D | Discord |
| E | Microsoft Excel |
| F | Firefox |
| G | ChatGPT |
| I | Microsoft PowerPoint |
| K | Docker |
| L | Slack |
| M | Mullvad VPN |
| O | Microsoft Outlook |
| P | App Store |
| R | Trello |
| S | Spotify |
| T | Microsoft Teams |
| W | WhatsApp |
| Y | Microsoft Word |

### Website Shortcuts (Hyper+W, then...)

| Key | Website |
|-----|---------|
| O | OneDrive Live |
| G | GitHub |
| D | DeepL |
| Y | YouTube |

### Finder Shortcuts (Hyper+F, then...)

| Key | Location |
|-----|----------|
| D | Downloads |
| S | Studies |
| P | Audio Processed |

### System Actions (Hyper+N, then...)

| Key | Action |
|-----|--------|
| C | Clear Notifications |

### Settings Shortcuts (Hyper+S, then...)

| Key | System Preference |
|-----|------------------|
| U | Software Update |
| D | Displays/Arrange |
| P | Privacy/Accessibility |
| W | Wi-Fi |
| B | Bluetooth |

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