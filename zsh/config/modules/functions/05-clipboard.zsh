# ===============================
# CROSS-PLATFORM CLIPBOARD
# ===============================
# Provides consistent pbcopy/pbpaste interface across all platforms:
# - macOS: native pbcopy/pbpaste
# - WSL: clip.exe / PowerShell Get-Clipboard
# - Linux Wayland: wl-copy/wl-paste
# - Linux X11: xclip (preferred) or xsel (fallback)

# Check if clipboard is available (native command or cross-platform function)
# Usage: if zdotfiles_has_clipboard; then ... | pbcopy; fi
zdotfiles_has_clipboard() {
    (( ${+commands[pbcopy]} || ${+functions[pbcopy]} )) && \
    (( ${+commands[pbpaste]} || ${+functions[pbpaste]} ))
}

# Skip setup if both pbcopy and pbpaste already available (includes macOS)
zdotfiles_has_clipboard && return

if zdotfiles_is_wsl; then
    # WSL: use Windows clipboard utilities
    pbcopy() { /mnt/c/Windows/System32/clip.exe; }
    pbpaste() {
        local out=$(/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -NoProfile -Command Get-Clipboard)
        print -r -- "${out//$'\r'/}"  # Strip all CR (Windows line endings)
    }
elif [[ -n "$WAYLAND_DISPLAY" ]] && (( ${+commands[wl-copy]} && ${+commands[wl-paste]} )); then
    # Linux Wayland
    pbcopy() { wl-copy; }
    pbpaste() { wl-paste; }
elif [[ -n "$DISPLAY" ]] && (( ${+commands[xclip]} )); then
    # Linux X11 (xclip)
    pbcopy() { xclip -selection clipboard; }
    pbpaste() { xclip -selection clipboard -o; }
elif [[ -n "$DISPLAY" ]] && (( ${+commands[xsel]} )); then
    # Linux X11 (xsel fallback)
    pbcopy() { xsel --clipboard --input; }
    pbpaste() { xsel --clipboard --output; }
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
