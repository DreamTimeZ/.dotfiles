# 🧠 Zsh Keybindings Overview (Categorized & Fancy)

> 💡 Tip: `^X` = Ctrl+X, `^[` = ESC (Meta/Option), `^` = Ctrl, `M-` = Meta

---

## 🔤 Basic Line Editing

| Key       | Function                             |
|-----------|--------------------------------------|
| `Ctrl+A`  | Beginning of line                    |
| `Ctrl+E`  | End of line                          |
| `Ctrl+B`  | Move backward one char               |
| `Ctrl+F`  | Move forward one char                |
| `Ctrl+U`  | Kill whole line                      |
| `Ctrl+K`  | Kill to end of line                  |
| `Ctrl+J`  | Accept line (Enter)                  |
| `Ctrl+W`  | Backward kill word                   |
| `Ctrl+H`  | Backward delete char                 |
| `Ctrl+D`  | Delete char or list completions      |
| `Ctrl+L`  | Clear screen                         |
| `Ctrl+M`  | Accept line (Enter)                  |
| `Ctrl+N`  | Next line in history                 |
| `Ctrl+P`  | Previous line in history             |
| `Ctrl+Y`  | Yank (paste from kill ring)          |

---

## 🔄 History Navigation

> **Note:** History search is handled by Atuin. Press `Ctrl+R` to open interactive history.

| Key         | Function                             |
|-------------|--------------------------------------|
| `Ctrl+R`    | Atuin history search                 |
| `Ctrl+S`    | History incremental search forward   |
| `ESC + p`   | History search backward              |
| `ESC + n`   | History search forward               |
| `ESC + <`   | Beginning of history buffer          |
| `ESC + >`   | End of history buffer                |

---

## 🔍 Fuzzy Finder Widgets (fzf)

| Key         | Function                |
|-------------|-------------------------|
| `Ctrl+I`    | `fzf-tab-complete` ✅ (custom) |
| `Ctrl+T`    | `fzf-file-widget` ✅ (custom) |
| `ESC + c`   | `fzf-cd-widget` ✅ (custom) |
| `ESC + .`   | Insert last word        |

---

## 🧠 Advanced History / Search

| Key             | Function                                  |
|------------------|-------------------------------------------|
| `Ctrl+O`         | Accept line and go to next history item   |
| `Ctrl+Q`         | Push line (Flow control unless `stty -ixon`) |
| `ESC + /`        | Expand history                            |
| `ESC + !`        | Expand history                            |

---

## 🔠 Word & Character Manipulation

| Key           | Function                  |
|---------------|---------------------------|
| `ESC + b`     | Backward word             |
| `ESC + f`     | Forward word              |
| `ESC + d`     | Kill word                 |
| `ESC + u`     | Uppercase word            |
| `ESC + l`     | Lowercase word            |
| `ESC + c`     | Capitalize word           |
| `ESC + t`     | Transpose words           |

---

## 📋 Clipboard / Kill Ring

| Key           | Function                        |
|---------------|----------------------------------|
| `ESC + w`     | Copy region as kill              |
| `ESC + y`     | Yank-pop                         |
| `Ctrl+X Ctrl+K` | Kill buffer                    |
| `Ctrl+X Ctrl+U` | Undo                          |

---

## 🖥️ Screen / Terminal Control

| Key         | Function                          |
|-------------|-----------------------------------|
| `ESC + L`   | Clear screen                      |
| `ESC + ?`   | Which command                     |
| `ESC + =`   | What cursor position              |
| `ESC + ^H`  | Backward kill word                |
| `ESC + ^L`  | Clear screen (alt binding)        |
| `ESC + ^M`  | Self-insert-unmeta (Meta+Enter)   |

---

## 📦 Special Functions (fzf-tab, vi-mode)

| Key            | Function                              |
|----------------|---------------------------------------|
| `Ctrl+X Ctrl+J` | vi-join                              |
| `Ctrl+X Ctrl+F` | vi-find-next-char                    |
| `Ctrl+X Ctrl+B` | vi-match-bracket                     |
| `Ctrl+X Ctrl+N` | Infer next history                   |
| `Ctrl+X Ctrl+V` | Enter vi-cmd-mode                    |
| `ESC + \|`      | vi-goto-column                       |
| `ESC + *`       | Expand word                          |

---

## 📂 Bracketed Paste / Misc

| Key             | Function                          |
|------------------|-----------------------------------|
| `^[[200~`        | Bracketed paste                   |
| `^[[3~`          | Delete char                       |
| `^[[3;9~`        | Kill line                         |
| `^[[79~`         | Custom: Backward kill to beginning|
| `^[[99~`         | Custom: Kill line                 |

---

## 🔢 Digit Arguments / Input Control

| Key         | Function              |
|-------------|-----------------------|
| `ESC + 0-9` | Digit argument input  |
| `ESC + -`   | Negative argument     |
