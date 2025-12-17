# ===============================
# CROSS-PLATFORM CLIPBOARD
# ===============================
# Provides consistent pbcopy/pbpaste interface across all platforms:
# - macOS: native pbcopy/pbpaste
# - WSL: clip.exe / PowerShell Get-Clipboard
# - Linux X11: xclip
# - Linux Wayland: wl-copy/wl-paste

# Skip if already defined (command or function)
(( ${+commands[pbcopy]} || ${+functions[pbcopy]} )) && return

if zdotfiles_is_macos; then
    # macOS: native commands exist, nothing to do
    :
elif zdotfiles_is_wsl; then
    # WSL: use Windows clipboard utilities
    pbcopy() { /mnt/c/Windows/System32/clip.exe; }
    pbpaste() {
        local out=$(/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -NoProfile -Command Get-Clipboard)
        print -r -- "${out//$'\r'/}"  # Strip all CR (Windows line endings)
    }
elif [[ -n "$WAYLAND_DISPLAY" ]] && (( ${+commands[wl-copy]} )); then
    # Linux Wayland
    pbcopy() { wl-copy; }
    pbpaste() { wl-paste; }
elif [[ -n "$DISPLAY" ]] && (( ${+commands[xclip]} )); then
    # Linux X11
    pbcopy() { xclip -selection clipboard; }
    pbpaste() { xclip -selection clipboard -o; }
else
    # Fallback: pass through with warning
    pbcopy() {
        print -u2 "pbcopy: no clipboard utility (install xclip or wl-clipboard)"
        cat
        return 1
    }
    pbpaste() {
        print -u2 "pbpaste: no clipboard utility (install xclip or wl-clipboard)"
        return 1
    }
fi
