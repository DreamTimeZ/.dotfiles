# iTerm2 (Legacy)

Superseded by Ghostty (`ghostty/config`). These settings are applied by hand in iTerm2's preferences. `setup.sh` still links `iterm2/.iterm2_shell_integration.zsh` on macOS.

## General

- Hotkey window: `control + cmd + enter`
- Show/hide all windows: `control + shift + cmd + enter`
- Closing: uncheck "Confirm 'Quit iTerm2 (`cmd + q`)'"
- Selection: check "Applications in terminal may access clipboard"

## Default Profile

- Window: 122 columns × 29 rows (fits quarter-screen window snapping)
- Keys: "Natural Text Editing" preset, plus:
  - `opt + delete` → Send Hex Codes: `0x17` (Ctrl+W, delete word backward)
  - `cmd + delete` → Send Hex Codes: `0x15` (Ctrl+U, delete to start of line, the same key Ghostty sends)
  - `fn + cmd + delete` → Send Hex Codes: `0x1b 0x5b 0x39 0x39 0x7e` (`ESC[99~`, delete to end of line, bound in `keybindings.zsh` only inside iTerm2)

## Hotkey Profile

- Text → Font: MesloLGS NF
- Keys → Key Mappings → Presets: "Natural Text Editing"
- Terminal → Notifications → Silence bell: checked
