# Hammerspoon

macOS hotkeys, modals, and window management. `setup.sh` links this directory to `~/.hammerspoon`.

- `init.lua`: entry point
- `modules/hotkeys/`: hotkey and modal system, see [Hotkeys Module](modules/hotkeys/README.md) to extend it
- `modules/mic_mute/`, `modules/startup/`: standalone modules

## Hotkeys

Hyper is Cmd+Ctrl+Alt+Shift, mapped from Caps Lock by Karabiner-Elements.

| Hotkey | Action |
|--------|--------|
| Hyper + A | Apps modal |
| Hyper + F | Finder modal |
| Hyper + W | Websites modal |
| Hyper + D | System modal |
| Hyper + S | Settings modal |
| Hyper + Space | Window modal (resize, move) |
| Hyper + M | Macros modal |
| Hyper + R | Routines modal (mappings only in the private repo) |
| Hyper + Return | Launch or focus Ghostty |
| Hyper + # | Transparent Ghostty, a separate instance (keycode 42, next to Return on German ISO) |
| F18 (no Hyper) | Toggle mic mute (Karabiner maps F5 to F18) |

Modal entries appear sorted alphabetically by description. The Apps, Finder, Websites, and Settings tables below are the defaults in `modules/hotkeys/config/config.lua`. A non-empty `modules/hotkeys/config/local/<modal>_mappings.lua` replaces them entirely (see [Local Hotkey Mappings](modules/hotkeys/config/local/README.md)). System, Window, and Macros are custom modals in `modules/hotkeys/modals/`, Macros takes its keys from `modules/hotkeys/config/macros_mappings.lua`.

### Apps (Hyper+A)

| Key | Application |
|-----|-------------|
| a | App Store |
| b | Books |
| c | Calendar |
| f | FaceTime |
| h | Photos |
| m | Mail |
| n | Notes |
| o | Maps |
| p | Preview |
| r | Reminders |
| s | Safari |
| t | Terminal |
| u | Music |
| v | QuickTime Player |
| w | Weather |
| x | Calculator |
| z | System Settings |

### Finder (Hyper+F)

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

### Websites (Hyper+W)

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

### System (Hyper+D)

| Key | Action |
|-----|--------|
| c | Clear Notifications |
| d | New Desktop |
| h | Reload Hammerspoon |
| n | Toggle Natural Scroll |
| r | Restart System (with confirmation) |
| s | Shutdown System (with confirmation) |

### Window (Hyper+Space)

Defined in `modules/hotkeys/modals/window.lua`.

| Key | Action |
|-----|--------|
| h / j / k / l | Left / bottom / top / right half |
| u / i / n / m | Top-left / top-right / bottom-left / bottom-right quarter |
| 1 / 2 / 3 | Left / middle / right third |
| f | Full screen |
| c | Center window |
| ´ / - | Larger / smaller |
| d | Default size |
| Right / Left | Next / previous screen |
| a | Cycle app windows |
| w | Mouse to window |
| g | Grid selector |
| 0 | Number overlays, then a digit focuses that window |
| s | Hidden and minimized windows |

### Macros (Hyper+M)

Defined in `modules/hotkeys/config/macros_mappings.lua`.

| Key | Action |
|-----|--------|
| a | Toggle Auto-Clicker |
| i | Show Macro Status |
| r | Toggle Recording |
| s | Stop All Macros |

### Settings (Hyper+S)

| Key | System Setting |
|-----|----------------|
| a | Accessibility |
| b | Bluetooth |
| c | Lock Screen |
| d | Displays |
| e | Network |
| f | Focus |
| i | Accessibility: Pointer Control |
| j | Device Management |
| k | Keyboard |
| l | Login Items & Extensions |
| m | Mouse |
| n | Accessibility: Motion |
| o | Spotlight |
| p | Privacy & Security |
| r | Wallpaper |
| s | Printers & Scanners |
| t | Screen Time |
| u | Software Update |
| v | VPN |
| w | Wi-Fi |
| y | Accessibility: Display |
