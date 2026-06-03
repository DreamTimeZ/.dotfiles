# Zsh Keybindings

Emacs mode (`bindkey -e`). Notation: `Ctrl+X`, `Alt+X` (Alt is the Meta/ESC
prefix and is case-insensitive for letters).

Two parts: bindings **set by this config** (`zsh/config/keybindings.zsh`, the
source of truth), then the **zsh emacs-keymap defaults** inherited underneath.
For zle widget names and the complete list, see `man zshzle` or run `bindkey -e`.
Verified against zsh 5.9. Run `kb` to view this file.

## Set by this config

### Editing

| Key | Action |
| --- | --- |
| `Alt+r` | Redo |
| `Ctrl+X Ctrl+E` | Edit the command line in `$EDITOR` |

### Line and word navigation

| Key | Action |
| --- | --- |
| `Home` / `End` | Beginning / end of line |
| `Ctrl+Left` / `Ctrl+Right` | Back / forward one word |
| `Alt+Left` / `Alt+Right` | Back / forward one word |

Home and End are bound in xterm-normal, application-cursor, and VT220 escape
forms for cross-terminal portability.

### Deletion

| Key | Action |
| --- | --- |
| `Delete` | Delete character forward |
| `Ctrl+Delete` / `Alt+Delete` | Delete word forward |
| `Ctrl+Backspace` / `Alt+Backspace` | Delete word backward |
| `Ctrl+U` | Delete backward to start of line |
| `Fn+Cmd+Delete` | Delete to end of line |

`Ctrl+U` rebinds the zsh default `kill-whole-line` to `backward-kill-line` to
match macOS Cocoa. `Ctrl+Backspace` (`^H`) rebinds `backward-delete-char` to
`backward-kill-word`. `Ctrl+Backspace` and `Alt+Backspace` also have
kitty-protocol forms. `Fn+Cmd+Delete` has an extra iTerm2-only sequence active
when `TERM_PROGRAM` is `iTerm.app`. Mac-style keys are translated by Ghostty
(see below).

### Screen

| Key | Action |
| --- | --- |
| `Ctrl+X l` | Clear screen and scrollback |

Inside tmux this also clears the tmux history.

## Plugin-provided

Not set in `keybindings.zsh`. Provided by plugins.

| Key | Action |
| --- | --- |
| `Ctrl+R` | History search (Atuin) |
| `Tab` | Fuzzy completion menu (fzf-tab) |

Inside the fzf-tab menu: `<` and `>` switch completion groups, `/` triggers
continuous completion, and `Ctrl+Space` toggles selection. Atuin is initialized
with `--disable-up-arrow`, so Up keeps normal previous-command behavior instead
of opening Atuin search.

## Ghostty key translations

Ghostty (`ghostty/config`) translates these Mac-style keys into the editing
actions above. `Cmd+Backspace` depends on the `Ctrl+U` rebinding. `Cmd+Delete`
and `Alt+Up`/`Alt+Down` reach zsh defaults.

| Key | Action |
| --- | --- |
| `Cmd+Backspace` | Delete to start of line (`Ctrl+U`) |
| `Cmd+Delete` | Delete to end of line (`Ctrl+K`) |
| `Alt+Up` / `Alt+Down` | Start / end of buffer |

## zsh emacs-keymap defaults

Provided by zsh's emacs keymap, not by this config. Keys this config or its
plugins rebind (`Ctrl+U`, `Ctrl+H`, `Ctrl+R`, `Tab`) behave as documented above.
Full list and widget names: `man zshzle`.

### Movement

| Key | Action |
| --- | --- |
| `Ctrl+A` / `Ctrl+E` | Beginning / end of line |
| `Ctrl+B` / `Ctrl+F` | Back / forward one character |
| `Alt+b` / `Alt+f` | Back / forward one word |
| `Alt+<` / `Alt+>` | Start / end of buffer |

Arrow keys move by character (Left/Right) and through history (Up/Down).

### Editing and undo

| Key | Action |
| --- | --- |
| `Backspace` | Delete previous character |
| `Ctrl+D` | Delete next char, or list completions |
| `Ctrl+T` | Transpose characters |
| `Alt+t` | Transpose words |
| `Alt+u` / `Alt+l` | Uppercase / lowercase word |
| `Alt+c` | Capitalize word |
| `Ctrl+V` | Insert next keypress literally |
| `Ctrl+X Ctrl+O` | Toggle overwrite mode |
| `Ctrl+_` , `Ctrl+X u` | Undo |
| `Alt+s` | Spell-correct the current word |

### Kill and yank

| Key | Action |
| --- | --- |
| `Ctrl+K` | Kill to end of line |
| `Ctrl+W` | Kill previous word |
| `Alt+d` | Kill next word |
| `Ctrl+Y` | Yank, paste last kill |
| `Alt+y` | Cycle the kill ring after a yank |
| `Alt+w` | Copy region to the kill ring |
| `Ctrl+Space` | Set mark |
| `Ctrl+X Ctrl+X` | Swap cursor and mark |
| `Ctrl+X Ctrl+K` | Kill the whole buffer |

### History

| Key | Action |
| --- | --- |
| `Ctrl+P` / `Ctrl+N` | Previous / next history line |
| `Alt+p` / `Alt+n` | Prefix history search back / forward |
| `Alt+.` , `Alt+_` | Insert last word of previous command |
| `Ctrl+O` | Accept line, fetch next from history |
| `Alt+a` | Accept line, keep for re-editing |
| `Alt+q` | Stash line, run next, then restore |

The zsh default for `Ctrl+R` is incremental search backward, replaced here by
Atuin (see Plugin-provided).

### Completion and expansion

| Key | Action |
| --- | --- |
| `Alt+x` | Run a ZLE widget by name |
| `Alt+z` | Repeat the last named widget |
| `Ctrl+X *` | Expand glob / parameter in place |
| `Ctrl+X g` | Preview what an expansion produces |
| `Alt+!` , `Alt+Space` | Expand history references |
| `Alt+?` | Show which command a word runs |

The zsh default for `Tab` is expand-or-complete; here it is fzf-tab.

### Arguments and control

| Key | Action |
| --- | --- |
| `Alt+0` .. `Alt+9` | Numeric repeat count |
| `Alt+-` | Negative argument |
| `Ctrl+L` | Clear screen |
| `Ctrl+G` | Abort the current operation |
| `Enter` | Accept the line (`Ctrl+M` / `Ctrl+J`) |

### Less common

Bound by default but rarely used day to day. See `man zshzle` for the rest.

| Key | Action |
| --- | --- |
| `Alt+h` | Run `run-help` for the command |
| `Alt+g` | Push buffer, fetch next line |
| `Alt+'` / `Alt+"` | Quote whole line / region |
| `Ctrl+X Ctrl+V` | Switch to vi command mode |
| `Ctrl+X Ctrl+J/F/B` | vi join / find-char / match-bracket |
| `Ctrl+X Ctrl+N` | Insert next line after history match |
